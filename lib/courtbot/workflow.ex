defmodule Courtbot.Workflow do
  alias Courtbot.{
    Case,
    Configuration,
    Repo,
    Subscriber,
    Workflow
  }

  import CourtbotWeb.Gettext

  require Logger

  defstruct [
    types: false,
    counties: false,
    queuing: false,
    locale: "en",
    state: :inquery,
    properties: %{},
    input: %{},
    context: %{}
  ]

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
        Logger.info(from <> ": user is unsubscribing")

        subscriptions = Repo.all(Subscriber.find_by_number(from))

        # User shouldn't receive this message as Twilio would have blocked the response but try and send it anyway.
        if Enum.empty?(subscriptions) do
          Logger.info(from <> ": user had no subscriptions")

          {:no_subscriptions, fsm}
        else
          Logger.info(from <> ": deleting all subscriptions")

          Repo.delete_all(Subscriber.find_by_number(from))

          reset(:unsubscribe, fsm)
        end

      body == "start" ->
        Logger.info(from <> ": user has 'unblocked' us")

        # Inform the user we blew away all their subscriptions due to being blocked
        {:resubscribe, fsm}

      body == "beepboop" ->

        %Case{id: case_id} = Case.find_with([case_number: "beepboop"])

          if Subscriber.already_subscribed?(case_id, from) do
            {:beep, fsm}
          else
            Logger.info(from <> ": user subscribing to debug case")

            %Subscriber{}
            |> Subscriber.changeset(%{case_id: case_id, phone_number: from, locale: locale})
            |> Repo.insert()

            {:boop, fsm}
          end

      String.contains?(body, gettext("delete")) ->
        if body === gettext("delete") do
          Logger.info(from <> ": user is unsubscribing from all cases")

          # Fetch all the subscriptions
          cases = Repo.all(Subscriber.find_by_number(from, :case))

          # Delete the subscription
          Repo.delete_all(Subscriber.find_by_number(from))

          reset(:unsubscribe, %{fsm | context: %{delete: cases}})
        else
          Logger.info(from <> ": user is unsubscribing to a specific case")

          [_, case_number] = String.split(body, " ")

          # Fetch all the subscriptions matching the case number and from.
          # TODO(ts): This may return more than one subscription if they are in seperate counties. Need to evaluate if this is confusing behavior.
          cases = Repo.all(Subscriber.find_by_number_and_case(from, case_number, :case))

          Repo.delete_all(Subscriber.find_by_number_and_case(from, case_number))

          reset(:unsubscribe, %{fsm | context: %{delete: cases}})
        end

      true ->
        case fsm do
         %Workflow{types: true} ->
           message(%{fsm | state: :type, properties: %{case_number: body}}, params)

         %Workflow{counties: true} ->
           message(%{fsm | state: :type, properties: %{case_number: body}}, params)

         _ -> message(%{fsm | state: :load_case, properties: %{case_number: body}}, params)
        end
    end
  end

  def message(fsm = %Workflow{counties: counties, properties: properties = %{case_number: case_number}, state: :type}, params) do
    with type when not is_nil(type) <- Case.check_types(case_number) do
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

  def message(fsm = %Workflow{state: :county, properties: properties}, params = [from: from, body: body]) do
    county =
      body
      |> String.replace(@county, "")
      |> String.trim()

    all_counties =
      Case.all_counties()
      |> Enum.map(&(String.downcase(&1)))

    if Enum.member?(all_counties, county) do
      message(%{fsm | state: :load_case, properties: Map.merge(properties, %{county: county})}, params)
    else
      Logger.info(from <> ": No county data for #{body}")

      reset(:no_case, fsm)
    end
  end

  def message(fsm = %Workflow{state: :load_case, properties: properties, queuing: queuing, types: types}, params) do
    case_details =
      properties
      |> Map.to_list()
      |> Case.find_with()

    case case_details do
      %Case{hearings: []} -> reset(:no_hearings, fsm)
      %Case{id: case_id, hearings: [%_{}]} -> message(%{fsm | state: :is_subscribed, properties: %{id: case_id}}, params)
      nil ->
        if queuing and types do
          # FIXME(ts): Add support for queuing
        else
          reset(:no_case, fsm)
        end
    end
  end

  def message(fsm = %Workflow{state: :is_subscribed, properties: properties}, _params = [from: from, body: _body]) do
    %Case{id: case_id} =
      properties
      |> Map.to_list()
      |> Case.find_with()

    if Subscriber.already_subscribed?(case_id, from) do
      reset(:already_subscribed, fsm)
    else
      {:subscribe, %{fsm | state: :subscribe}}
    end
  end

  def message(fsm = %Workflow{state: :subscribe, properties: properties, locale: locale}, _params = [from: from, body: body]) do
    %Case{id: case_id, case_number: case_number} =
      properties
      |> Map.to_list()
      |> Case.find_with()

    cond do
      Enum.member?(@accept_keywords, body) ->
        Logger.info(from <> ": user is subscribing to case: " <> case_number)

        %Subscriber{}
        |> Subscriber.changeset(%{case_id: case_id, phone_number: from, locale: locale})
        |> Repo.insert()

        reset(:reminder, fsm)

      Enum.member?(@reject_keywords, body) ->
        Logger.info(from <> ": user rejected reminder offer")

        reset(:reject_reminder, fsm)

      true ->
        Logger.info(from <> ": user has responded with an unknown reply: " <> body)

        {:yes_or_no, fsm}
    end
  end
end
