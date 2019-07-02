defmodule Courtbot.Workflow do
  @moduledoc """
  This is the Hello module.
  """
  alias Courtbot.{
    Case,
    Configuration,
    Repo,
    Subscriber,
    Workflow
  }

  import Ecto.Query

  import CourtbotWeb.Gettext

  defstruct types: false,
            counties: false,
            queuing: false,
            locale: "en",
            state: :inquery,
            properties: %{},
            input: %{},
            context: %{}

  @accept_keywords [
    gettext("y"),
    gettext("ye"),
    gettext("yes"),
    gettext("sure"),
    gettext("ok"),
    gettext("plz"),
    gettext("please")
  ]

  @reject_keywords [
    gettext("n"),
    gettext("no"),
    gettext("dont"),
    gettext("stop")
  ]

  # These are defined by Twilio. See https://support.twilio.com/hc/en-us/articles/223134027-Twilio-support-for-opt-out-keywords-SMS-STOP-filtering- for more detail.
  @unsubscribe_keywords [
    gettext("stop"),
    gettext("stopall"),
    gettext("cancel"),
    gettext("end"),
    gettext("quit"),
    gettext("unsubscribe")
  ]

  @county gettext("county")

  @doc """
  Initialize the workflow struct with configuration.
  """
  def init(fsm) do
    %{
      importer: %_{county_duplicates: county_duplicates},
      notifications: %_{queuing: queuing},
      types: types
    } = Configuration.get([:types, :importer, :notifications])

    %{fsm | types: length(types) > 0, counties: county_duplicates, queuing: queuing}
  end

  @doc """
  Reset the Workflow to the initial state.
  """
  def reset(response, fsm), do: {response, %{fsm | state: :inquery}}

  @doc """
  Handle the :inquery workflow state. This is the initial state a user will end up in.

  First check if the user wants to unsubscribe.

  If the user sends "subscribe" or "resubscribe" we want to make sure we catch this as the regex for case types in Idaho
  includes a check for "CR" and these two common words can be mistaken for a case number.

  Check if the user sends "Start" as this is a keyword from Twilio to tell them they'd like to continue receiving messages
  from us.

  Check if they send "Beepboop" which is the name of our debug case.

  Check if the user is sending "Delete" or "Delete <case number>"

  Otherwise assume the message is a case number and proceed to check it's type and any other conditions.
  """
  def message(fsm = %Workflow{state: :inquery, locale: locale}, params = [from: from, body: body]) do
    cond do
      # If the user wants to unsubscribe handle that up front.
      Enum.member?(@unsubscribe_keywords, body) ->
        subscriptions =
          from
          |> Subscriber.find_by_number()
          |> Repo.all()

        # User shouldn't receive this message as Twilio would have blocked the response but try and send it anyway.
        if Enum.empty?(subscriptions) do
          :telemetry.execute([:workflow, :inquery, :no_subscriptions], %{}, %{})

          {:no_subscriptions, fsm}
        else
          Repo.delete_all(Subscriber.find_by_number(from))

          :telemetry.execute([:workflow, :inquery, :unsubscribe], %{}, %{})

          reset(:unsubscribe, fsm)
        end

      # Treat these two as special cases
      body == "subscribe" or body == "resubscribe" ->
        :telemetry.execute([:workflow, :inquery, :invalid], %{}, %{})

        reset(:invalid, fsm)

      body == "start" ->
        case Repo.one(Subscriber.find_by_number(from, :case)) do
          %Subscriber{} ->
            :telemetry.execute([:workflow, :inquery, :invalid], %{}, %{})

            {:invalid, fsm}

          # Inform the user we blew away all their subscriptions due to being blocked
          _ ->
            :telemetry.execute([:workflow, :inquery, :resubscribe], %{}, %{})

            {:resubscribe, fsm}
        end

      body == "beepboop" ->
        case Case.find_with(case_number: "beepboop") do
          %Case{id: case_id} ->
            if Subscriber.already?(case_id, from) do
              :telemetry.execute([:workflow, :inquery, :beep], %{}, %{})

              {:beep, fsm}
            else
              %Subscriber{}
              |> Subscriber.changeset(%{case_id: case_id, phone_number: from, locale: locale})
              |> Repo.insert()

              :telemetry.execute([:workflow, :inquery, :boop], %{}, %{})

              {:boop, fsm}
            end

          _ ->
            :telemetry.execute([:workflow, :inquery, :invaid], %{}, %{})

            reset(:invalid, fsm)
        end

      String.contains?(body, gettext("delete")) ->
        cases =
          if body === gettext("delete") do
            # Fetch all the subscriptions
            Repo.all(Subscriber.find_by_number(from, :case))
          else
            [_, case_number] = String.split(body, " ")

            # Fetch all the subscriptions matching the case number and from.
            # TODO(ts): This may return more than one subscription if they are in separate counties. Need to evaluate if this is confusing behavior.
            Repo.all(Subscriber.find_by_number_and_case(from, case_number, :case))
          end

        with case_subscriptions when cases != [] <- cases do
          :telemetry.execute([:workflow, :inquery, :unsubscribe_confirm], %{}, %{})

          {:unsubscribe_confirm,
           %{fsm | state: :unsubscribe, context: %{cases: case_subscriptions}}}
        else
          _ ->
            :telemetry.execute([:workflow, :inquery, :no_subscriptions], %{}, %{})

            reset(:no_subscriptions, fsm)
        end

      true ->
        case fsm do
          %Workflow{types: true} ->
            message(%{fsm | state: :type, properties: %{case_number: body}}, params)

          %Workflow{counties: true} ->
            message(%{fsm | state: :type, properties: %{case_number: body}}, params)

          _ ->
            message(%{fsm | state: :load_case, properties: %{case_number: body}}, params)
        end
    end
  end

  @doc """
  Handle the :unsubscribe workflow state. If a user is unsubscribing we send them a message to confirm they'd no longer like
  to be subscribing to a case.

  This function handles the actual deletion if a user confirms they'd like to unsubscribe or respondings with the a yes or no
  prompt until the user responds with something Courtbot understands.

  """
  def message(
        fsm = %Workflow{state: :unsubscribe, input: %{inquery: inquery}},
        _params = [from: from, body: body]
      ) do
    # Normalize the inquery like we would any previous input. This is done here as sometimes we want to maintain the exact text
    # a user sent in originally for repeating it back to them. Think of cases like saying a case number does not exist.
    normalize_inquery =
      inquery
      |> String.trim()
      |> String.replace("-", "")
      |> String.replace("_", "")
      |> String.replace(",", "")
      |> String.downcase()

    cases =
      cond do
        normalize_inquery === gettext("delete") ->
          # Fetch all the subscriptions
          from
          |> Subscriber.find_by_number(:case)
          |> Repo.all()

        String.contains?(normalize_inquery, gettext("delete")) ->
          [_, case_number] = String.split(normalize_inquery, " ")

          # Fetch all the subscriptions matching the case number and from.
          # TODO(ts): This may return more than one subscription if they are in separate counties. Need to evaluate if
          # this is confusing behavior.
          from
          |> Subscriber.find_by_number_and_case(case_number, :case)
          |> Repo.all()
      end

    cond do
      Enum.member?(@accept_keywords, body) ->
        # Delete the subscription
        from
        |> Subscriber.find_by_number()
        |> Repo.delete_all()

        :telemetry.execute([:workflow, :unsubscribe, :unsubcribe], %{}, %{})
        reset(:unsubscribe, fsm)

      Enum.member?(@reject_keywords, body) ->
        :telemetry.execute([:workflow, :unsubscribe, :unsubscribe_reject], %{}, %{})
        reset(:unsubscribe_reject, fsm)

      true ->
        :telemetry.execute([:workflow, :unsubscribe, :unsubscribe_yes_or_no], %{}, %{})

        {:unsubscribe_yes_or_no, %{fsm | context: %{cases: cases}}}
    end
  end

  @doc """
  Handle the :type workflow state. This is a "virtual" state as there is no way for a user to directly hit this state
  without going through another first.


  Check if a users input matches regex for a case type defined in configuration. If they do, and counties are enabled
  then kick them over inquerying about their county. If counties is not enabled then ship them off to the load_case state.

  If nothing matches then tell the user the :invalid response.

  """
  def message(
        fsm = %Workflow{
          counties: counties,
          properties: properties = %{case_number: case_number},
          state: :type
        },
        params
      ) do
    %{types: types} = Configuration.get([:types])

    with type when not is_nil(type) <- Case.check_types(case_number, types) do
      type = Atom.to_string(type)

      if counties do
        :telemetry.execute([:workflow, :type, :county], %{}, %{})
        {:county, %{fsm | state: :county, properties: Map.merge(properties, %{type: type})}}
      else
        message(%{fsm | state: :load_case}, params)
      end
    else
      nil ->
        :telemetry.execute([:workflow, :type, :invaild], %{}, %{})
        reset(:invalid, fsm)
    end
  end

  @doc """
  Handle the :county workflow state. If counties are enabled then we ask the user what county they are interested in.

  This state exists to help support multiple counties where there is potentially duplicate case numbers.
  """
  def message(
        fsm = %Workflow{state: :county, properties: properties},
        params = [from: _from, body: body]
      ) do
    county =
      body
      |> String.replace(@county, "")
      |> String.trim()

    all_counties =
      Case.all_counties()
      |> Enum.map(&String.downcase(&1))

    if Enum.member?(all_counties, county) do
      :telemetry.execute([:workflow, :state, :county], %{}, %{})

      message(
        %{fsm | state: :load_case, properties: Map.merge(properties, %{county: county})},
        params
      )
    else
      :telemetry.execute([:workflow, :state, :no_case], %{}, %{})

      reset(:no_case, fsm)
    end
  end

  @doc """
  Handle the :load_case workflow state.
  """
  def message(
        fsm = %Workflow{state: :load_case, properties: properties, queuing: queuing, types: types},
        params
      ) do
    case_details =
      properties
      |> Map.to_list()
      |> Case.find_with()

    case case_details do
      %Case{id: case_id, hearings: []} ->
        {:no_hearings, %{fsm | state: :no_hearings, properties: %{id: case_id}}}

      %Case{id: case_id, hearings: [%_{}]} ->
        message(%{fsm | state: :is_subscribed, properties: %{id: case_id}}, params)

      nil ->
        if queuing and types do
          # TOOO(ts): Add support for queuing
        else
          reset(:no_case, fsm)
        end
    end
  end

  @doc """
  Handle the :no_hearings workflow state.
  """
  def message(
        fsm = %Workflow{state: :no_hearings, properties: properties, locale: locale},
        _params = [from: from, body: body]
      ) do
    %Case{id: case_id} =
      properties
      |> Map.to_list()
      |> Case.find_with()

    cond do
      Enum.member?(@accept_keywords, body) ->
        {:ok, subscriber} =
          %Subscriber{}
          |> Subscriber.changeset(%{
            case_id: case_id,
            phone_number: from,
            locale: locale,
            queued: true
          })
          |> Repo.insert()

        cases = from(s in Subscriber, where: s.id == ^subscriber.id, preload: :case) |> Repo.all()

        reset(:no_hearings_confirm, %{fsm | context: %{cases: cases}})

      Enum.member?(@reject_keywords, body) ->
        reset(:reject_reminder, fsm)

      true ->
        {:no_hearings_yes_or_no, fsm}
    end
  end

  @doc """
  Handle the :is_subscribed workflow state.
  """
  def message(
        fsm = %Workflow{state: :is_subscribed, properties: properties},
        _params = [from: from, body: _body]
      ) do
    %Case{id: case_id} =
      properties
      |> Map.to_list()
      |> Case.find_with()

    if Subscriber.already?(case_id, from) do
      reset(:subscribed_already, fsm)
    else
      {:subscribe, %{fsm | state: :subscribe}}
    end
  end

  @doc """
  Handle the :subscribe workflow state.

  If the user accepts we write to the subscribers table. If they rejext then we ask them again.
  """
  def message(
        fsm = %Workflow{state: :subscribe, properties: properties, locale: locale},
        _params = [from: from, body: body]
      ) do
    %Case{id: case_id} =
      properties
      |> Map.to_list()
      |> Case.find_with()

    cond do
      Enum.member?(@accept_keywords, body) ->
        %Subscriber{}
        |> Subscriber.changeset(%{case_id: case_id, phone_number: from, locale: locale})
        |> Repo.insert()

        reset(:reminder, fsm)

      Enum.member?(@reject_keywords, body) ->
        reset(:reject_reminder, fsm)

      true ->
        {:yes_or_no, fsm}
    end
  end

  def telemetry() do
    :telemetry.attach(
      "courtbot-telemetry",
      [:workflow, :request, :done],
      &Courtbot.TelemetryHandler.handle_event/4,
      nil
    )

    :telemetry.attach(
      "courtbot-telemetry",
      [:workflow, :request, :done],
      &Courtbot.TelemetryHandler.handle_event/4,
      nil
    )

    :telemetry.attach(
      "courtbot-telemetry",
      [:workflow, :request, :done],
      &Courtbot.TelemetryHandler.handle_event/4,
      nil
    )
  end
end
