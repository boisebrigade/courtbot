defmodule Courtbot.Workflow do
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

  def init(fsm) do
    %{
      importer: %_{county_duplicates: county_duplicates},
      notifications: %_{queuing: queuing},
      types: types
    } = Configuration.get([:types, :importer, :notifications])

    %{fsm | types: length(types) > 0, counties: county_duplicates, queuing: queuing}
  end

  def reset(response, fsm), do: {response, %{fsm | state: :inquery}}

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
          {:no_subscriptions, fsm}
        else
          Repo.delete_all(Subscriber.find_by_number(from))

          reset(:unsubscribe, fsm)
        end

      # Treat these two as special cases
      body == "subscribe" or body == "resubscribe" ->
        reset(:invalid, fsm)

      body == "start" ->
        # Inform the user we blew away all their subscriptions due to being blocked
        {:resubscribe, fsm}

      body == "beepboop" ->
        case Case.find_with(case_number: "beepboop") do
          %Case{id: case_id} ->
            if Subscriber.already?(case_id, from) do
              {:beep, fsm}
            else
              %Subscriber{}
              |> Subscriber.changeset(%{case_id: case_id, phone_number: from, locale: locale})
              |> Repo.insert()

              {:boop, fsm}
            end

          _ ->
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
          {:unsubscribe_confirm,
           %{fsm | state: :unsubscribe, context: %{cases: case_subscriptions}}}
        else
          _ -> reset(:no_subscriptions, fsm)
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

  def message(
        fsm = %Workflow{state: :unsubscribe, input: %{inquery: inquery}},
        _params = [from: from, body: body]
      ) do
    cases =
      if inquery === gettext("delete") do
        # Fetch all the subscriptions
        from
        |> Subscriber.find_by_number(:case)
        |> Repo.all()
      else
        [_, case_number] = String.split(inquery, " ")

        # Fetch all the subscriptions matching the case number and from.
        # TODO(ts): This may return more than one subscription if they are in separate counties. Need to evaluate if this is confusing behavior.
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

        reset(:unsubscribe, fsm)

      Enum.member?(@reject_keywords, body) ->
        reset(:unsubscribe_reject, fsm)

      true ->
        {:unsubscribe_yes_or_no, %{fsm | context: %{cases: cases}}}
    end
  end

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
        {:county, %{fsm | state: :county, properties: Map.merge(properties, %{type: type})}}
      else
        message(%{fsm | state: :load_case}, params)
      end
    else
      nil -> reset(:invalid, fsm)
    end
  end

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
      message(
        %{fsm | state: :load_case, properties: Map.merge(properties, %{county: county})},
        params
      )
    else
      reset(:no_case, fsm)
    end
  end

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
          # FIXME(ts): Add support for queuing
        else
          reset(:no_case, fsm)
        end
    end
  end

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
end
