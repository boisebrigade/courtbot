defmodule CourtbotWeb.Response do
  @moduledoc false
  alias Courtbot.{
    Case,
    Configuration,
    Subscriber,
    Workflow
  }

  import CourtbotWeb.Gettext

  def get_message(key, locale) when is_atom(key), do: response(key, %{locale: locale})

  def get_message({key, case = %Case{}}, locale) do
    params =
      %{}
      |> Map.merge(format_case_details(case))
      |> Map.merge(custom_variables())

    Gettext.with_locale(locale, fn ->
      response(key, params)
    end)
  end

  def get_message(
        {key,
         fsm = %Workflow{
           locale: locale,
           properties: properties = %{id: _},
           input: input,
           context: context
         }}
      ) do
    case_details =
      properties
      |> Map.to_list()
      |> Case.find_with()

    params =
      %{input: input, context: context}
      |> Map.merge(format_case_details(case_details))
      |> Map.merge(custom_variables())

    params =
      params
      |> Map.merge(cases_context(params))
      |> Map.merge(user_supplied_context(params))

    Gettext.with_locale(locale, fn ->
      {response(key, params), fsm}
    end)
  end

  def get_message(
        {key,
         fsm = %Workflow{locale: locale, properties: properties, input: input, context: context}}
      ) do
    params =
      %{input: input, context: context}
      |> Map.merge(properties)
      |> Map.merge(custom_variables())

    params =
      params
      |> Map.merge(cases_context(params))
      |> Map.merge(user_supplied_context(params))

    Gettext.with_locale(locale, fn ->
      {response(key, params), fsm}
    end)
  end

  defp response(:beep, _), do: "beep"
  defp response(:boop, _), do: "boop"
  defp response(:beepboop, _), do: "BEEPBOOP"
  defp response(:debug, _), do: "BEEPBOOP"

  defp response(:unsubscribe_confirm, params) do
    respond("Are you sure you want to stop getting reminders for %{cases}?", params)
  end

  defp response(:unsubscribe_reject, _params) do
    respond("OK. You said \"No\" so we will still send you reminders.")
  end

  defp response(:unsubscribe_yes_or_no, params) do
    respond(
      "Sorry, I did not understand. Do you want to stop getting reminders for %{cases}? Reply YES or NO",
      params
    )
  end

  defp response(:unsubscribe, _params) do
    respond(
      "OK. We will stop sending reminders. Reply with a case number to sign up for a reminder. For example: CR00-19-00011"
    )
  end

  defp response(:subscribed_already, _params) do
    respond(
      "You are already subscribed to this case. To stop getting reminders reply with DELETE."
    )
  end

  defp response(:resubscribe, _params) do
    respond(
      "You are not subscribed to any cases. Reply with a case number to sign up for reminders. For example: CR00-19-00011"
    )
  end

  defp response(:county, _params) do
    respond("We need more information to find your case. Which county is this case in?")
  end

  defp response(:invalid, _params) do
    respond("Reply with a case number to sign up for reminders. For example: CR00-19-00011")
  end

  defp response(:no_case, params = %{case_number: _}) do
    params = user_supplied_context(params)

    respond(
      "We did not find case %{user_supplied_case_number} in that county. Please check your case number and county. Reply with a case number to sign up for reminders. For example: CR00-19-00011",
      params
    )
  end

  defp response(:no_hearings, params = %{case_number: _, court_url: _, parties: _, county: _}) do
    respond(
      "We found a case for %{parties} in %{county} County. We do not see any future hearings scheduled. You should always confirm your hearing date and time by going to %{court_url}. Would you like to be notified when a hearing is scheduled?",
      params
    )
  end

  defp response(
         :no_hearings_confirm,
         params = %{case_number: _, court_url: _, parties: _, county: _}
       ) do
    respond(
      "OK. We will text you when a hearing is scheduled for case %{cases}. Note that court schedules may change. You should always confirm your hearing date and time by going to %{court_url}.",
      params
    )
  end

  defp response(:no_hearings_yes_or_no, _params) do
    respond(
      "Sorry, I did not understand. Would you like to be notified when a hearing is scheduled? Reply YES or NO"
    )
  end

  defp response(:queued, params = %{time: _, date: _, court_url: _, parties: _, county: _}) do
    respond(
      "A upcoming hearing has been scheduled for %{parties} in %{county} County. The next hearing is on %{date}, at %{time}. Note that court schedules may change. You should always confirm your hearing date and time by going to %{court_url}.",
      params
    )
  end

  defp response(:no_subscriptions, _params) do
    respond(
      "You are not subscribed to any cases. We won't send you any reminders. Reply with a case number to sign up for a reminder. For example: CR00-19-00011"
    )
  end

  defp response(:subscribe, params = %{date: _, time: _, parties: _, county: _}) do
    respond(
      "We found a case for %{parties} in %{county} County. The next hearing is on %{date}, at %{time}. Would you like a reminder a day before the next hearing date?",
      params
    )
  end

  defp response(:reminder, params = %{court_url: _}) do
    respond(
      "OK. We will text you a courtesy reminder the day before the hearing date. Note that court schedules may change. You should always confirm your hearing date and time by going to %{court_url}.",
      params
    )
  end

  defp response(:reject_reminder, params = %{court_url: _}) do
    respond(
      "You said \"No\" so we won’t text you a reminder. You should always confirm your hearing date and time by going to %{court_url}.",
      params
    )
  end

  defp response(:remind, params = %{case_number: _, date: _, time: _, court_url: _}) do
    respond(
      "This is a reminder for case %{case_number}. The next hearing is tomorrow, %{date}, at %{time}. You can go to %{court_url} for more information.",
      params
    )
  end

  defp response(:yes_or_no, _params) do
    respond(
      "Sorry, I did not understand. Would you like a courtesy reminder a day before the hearing? Reply YES or NO"
    )
  end

  def custom_variables() do
    %{variables: variables} = Configuration.get([:variables])

    Enum.reduce(variables, %{}, fn %_{name: name, value: value}, acc ->
      Map.put(acc, String.to_atom(name), value)
    end)
  end

  def cases_context(params = %{context: %{cases: subscriptions}}) do
    debug_case_id =
      case Case.find_with(case_number: "beepboop") do
        %Case{id: debug_case_id} -> debug_case_id
        _ -> "no debug case"
      end

    cases =
      Enum.reduce(subscriptions, [], fn
        %Subscriber{case_id: case_id}, acc when case_id == debug_case_id ->
          [
            gettext("Courtbot's debug case") | acc
          ]

        %Subscriber{case: %Case{formatted_case_number: case_number, county: county}}, acc
        when county != "" ->
          case_number = Case.clean_case_number(case_number)

          [
            Gettext.dgettext(
              CourtbotWeb.Gettext,
              "response",
              "%{case_number} in %{county} County",
              %{case_number: case_number, county: county}
            )
            | acc
          ]

        %Subscriber{case: %Case{formatted_case_number: case_number}}, acc ->
          case_number = Case.clean_case_number(case_number)

          [case_number | acc]
      end)

    Map.merge(params, %{cases: Enum.join(cases, ", and ")})
  end

  def cases_context(params), do: params

  defp user_supplied_context(params = %{input: %{inquery: user_supplied_case_number}}) do
    Map.put(params, :user_supplied_case_number, user_supplied_case_number)
  end

  defp user_supplied_context(params = %{case_number: case_number}) do
    Map.put(params, :user_supplied_case_number, case_number)
  end

  defp user_supplied_context(params), do: params

  defp respond(message, params \\ %{}) do
    Gettext.dgettext(
      CourtbotWeb.Gettext,
      "response",
      message,
      params
    )
  end

  defp format_case_details(case) do
    details =
      with case = %{hearings: [hearing]} <- Case.format(case) do
        Enum.reduce([:hearings], case, &Map.delete(&2, &1))
        |> Map.merge(hearing)
      else
        case -> case
      end

    %{formatted_case_number: format_case_number} = details

    Enum.reduce([:case_number, :formatted_case_number], details, &Map.delete(&2, &1))
    |> Map.merge(%{case_number: format_case_number})
  end
end
