defmodule CourtbotWeb.Response do
  alias Courtbot.{
    Case,
    Configuration,
    Workflow
  }

  import CourtbotWeb.Gettext

  def get_message({key, case = %Case{}}, locale) do
    params =
      %{locale: locale}
      |> Map.merge(format_case_details(case))
      |> Map.merge(custom_variables())

    response(key, params)
  end

  def get_message({key, fsm = %Workflow{locale: locale, properties: properties = %{id: _}, input: input, context: context}}) do
    case_details =
      properties
      |> Map.to_list()
      |> Case.find_with()

    params =
      %{locale: locale, input: input, context: context}
      |> Map.merge(format_case_details(case_details))
      |> Map.merge(custom_variables())

    {response(key, params), fsm}
  end

  def get_message({key, fsm = %Workflow{locale: locale, properties: properties, input: input, context: context}}) do
    params =
      %{locale: locale, input: input, context: context}
      |> Map.merge(properties)
      |> Map.merge(custom_variables())

    {response(key, params), fsm}
  end

  defp response(:beep, _), do: "beep"
  defp response(:boop, _), do: "boop"

  defp response(:unsubscribe, params = %{locale: locale}) do
    %Case{id: debug_case_id} = Case.find_with([case_number: "beepboop"])

    with %{context: %{delete: subscriptions}} <- params do
      Gettext.with_locale(locale, fn ->
        cases =
          Enum.reduce(subscriptions, [], fn %Courtbot.Subscriber{case_id: case_id}, acc when case_id == debug_case_id ->
              [Gettext.with_locale(locale, fn ->
                gettext("Courtbot's debug case")
              end) | acc]
            %Courtbot.Subscriber{case: %Courtbot.Case{formatted_case_number: case_number, county: county}}, acc ->
              case_number =
                case_number
                |> String.trim()
                |> String.replace("-", "")
                |> String.replace("_", "")
                |> String.replace(",", "")

              [Gettext.dgettext(
                CourtbotWeb.Gettext,
                "response",
                "%{case_number} in %{county}",
                %{case_number: case_number, county: county}
              ) | acc]
          end)


        Gettext.dgettext(
          CourtbotWeb.Gettext,
          "response",
          "OK. We will stop sending reminders for %{cases}. Reply with a case number to sign up for a reminder. For example a case number looks like: CR01-18-22672",
          %{cases: Enum.join(cases, ", and ")}
        )

      end)

      else
      _ -> Gettext.with_locale(locale, fn ->
        gettext("OK. We will stop sending reminders for all cases you are subscribed to.")
      end)
    end
  end

  defp response(:already_subscribed, _params = %{locale: locale}) do
    Gettext.with_locale(locale, fn ->
      gettext(
        "You are already subscribed to this case. To unsubscribe to this case reply with DELETE."
      )
    end)
  end

  defp response(:resubscribe, _params = %{locale: locale}) do
    Gettext.with_locale(locale, fn ->
      gettext("You will need to resubscribe to the case to receive hearing reminders.")
    end)
  end

  defp response(:county, _params = %{locale: locale}) do
    Gettext.with_locale(locale, fn ->
      gettext("Which county are you interested in?")
    end)
  end

  defp response(:invalid, _params = %{locale: locale}) do
    Gettext.with_locale(locale, fn ->
      gettext("Reply with a case number to sign up for a reminder. For example a case number looks like: CR01-18-22672")
    end)
  end

  defp response(:no_case, params = %{locale: locale, case_number: case_number}) do
    input_case_number = with %{input: %{inquery: user_supplied_case_number}} <- params do
      user_supplied_case_number
      else
      _ -> case_number
    end

    params = Map.put(params, :user_supplied_case_number, input_case_number)

    Gettext.with_locale(locale, fn ->
      Gettext.dgettext(
        CourtbotWeb.Gettext,
        "response",
        "We did not find case %{user_supplied_case_number} in that county. Please check your case number and county. Reply with a case number to sign up for a reminder. For example a case number looks like: CR01-18-22672",
        params
      )
    end)
  end

  defp response(:no_hearings, params = %{locale: locale, case_number: case_number, court_url: _}) do
    input_case_number = with %{input: %{inquery: user_supplied_case_number}} <- params do
      user_supplied_case_number
    else
      _ -> case_number
    end

    params = Map.put(params, :user_supplied_case_number, input_case_number)

    Gettext.with_locale(locale, fn ->
      Gettext.dgettext(
        CourtbotWeb.Gettext,
        "response",
        "We did not find any upcoming hearings for %{user_supplied_case_number} in that county. Please check your case number and county. Note that court schedules may change. You should always confirm your hearing date and time by going to %{court_url}",
        params
      )
    end)
  end

  defp response(:no_subscriptions, _params = %{locale: locale}) do
    Gettext.with_locale(locale, fn ->
      gettext("You are not subscribed to any cases. We won't send you any reminders. Reply with a case number to sign up for a reminder. For example a case number looks like: CR01-18-22672")
    end)
  end

  defp response(:subscribe, params = %{locale: locale, date: _, time: _, first_name: _, last_name: _, county: _}) do
    Gettext.with_locale(locale, fn ->
      Gettext.dgettext(
        CourtbotWeb.Gettext,
        "subscribe",
        "We found a case for %{first_name} %{last_name} in %{county} County. The next hearing is on %{date}, at %{time}. Would you like a reminder a day before the next hearing date?",
        params
      )
    end)
  end

  defp response(:reminder, params = %{locale: locale, court_url: _}) do
    Gettext.with_locale(locale, fn ->
      Gettext.dgettext(
        CourtbotWeb.Gettext,
        "response",
        "OK. We will text you a courtesy reminder the day before the hearing date. Note that court schedules may change. You should always confirm your hearing date and time by going to %{court_url}",
        params
      )
    end)
  end

  defp response(:reject_reminder, params = %{locale: locale, court_url: _}) do
    Gettext.with_locale(locale, fn ->
      Gettext.dgettext(
        CourtbotWeb.Gettext,
        "response",
        "You said \"No\" so we won’t text you a reminder. Note that court schedules may change. You should always confirm your hearing date and time by going to %{court_url}",
        params
      )
    end)
  end

  defp response(
         :remind,
         _params = %{
           locale: locale,
           case_number: case_number,
           date: date,
           time: time,
           court_url: court_url
         }
       ) do
    Gettext.with_locale(locale, fn ->
      Gettext.dgettext(
        CourtbotWeb.Gettext,
        "response",
        "This is a reminder for case %{case_number}. The next hearing is tomorrow, %{date}, at %{time}. You can go to %{court_url} for more information.",
        case_number: case_number,
        date: date,
        time: time,
        court_url: court_url
      )
    end)
  end

  defp response(:yes_or_no, _params = %{locale: locale}) do
    Gettext.with_locale(locale, fn ->
      gettext(
        "Sorry, I did not understand. Would you like a courtesy reminder a day before the hearing? Reply YES or NO"
      )
    end)
  end

  def custom_variables() do
    %{variables: variables} = Configuration.get([:variables])

    Enum.reduce(variables, %{}, fn %_{name: name, value: value}, acc -> Map.put(acc, String.to_atom(name), value) end)
  end

  defp format_case_details(case) do
    case = %{formatted_case_number: format_case_number, hearings: [hearing]} = Case.format(case)

    Enum.reduce([:case_number, :formatted_case_number, :hearings], case, &Map.delete(&2, &1))
    |> Map.merge(hearing)
    |> Map.merge(%{case_number: format_case_number})
  end
end
