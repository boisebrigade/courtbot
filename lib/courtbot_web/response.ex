defmodule CourtbotWeb.Response do
  @moduledoc """
  Provides `message/2` to provide responses based upon the type given and the params avaliable
  """
  alias Courtbot.Case

  import CourtbotWeb.Gettext


  defp message_params() do
    Application.get_env(:courtbot, Courtbot, %{})
    |> Map.new()
    |> Map.take([:court_url, :queued_ttl_days, :subscribe_limit])
  end

  defp format_case_details(case) do
    case = %{formatted_case_number: format_case_number, hearings: [hearing]} = Case.format(case)

    Enum.reduce([:case_number, :formatted_case_number, :hearings], case, &(Map.delete(&2, &1)))
    |> Map.merge(hearing)
    |> Map.merge(%{case_number: format_case_number})
  end

  def message(types, params) when is_list(types) do
    Enum.reduce(types, "", fn type, acc ->
      params = Map.merge(params, message_params())

      params =
        if params[:case] do
          case = params[:case]

          params
          |> Map.delete(:case)
          |> Map.merge(format_case_details(case))
        else
          params
        end

      "#{acc} #{response(type, params)}"
    end)
    |> String.trim()
  end

  def message(type, params), do: message([type], Map.merge(message_params(), params))

  defp response(:unsubscribe, _params = %{locale: locale}) do
    Gettext.with_locale(locale, fn ->
      gettext("OK. We will stop sending reminders for all cases you are subscribed to.")
    end)
  end

  defp response(:unsubscribe, _params = %{locale: locale, case_number: case_number}) do
    Gettext.with_locale(locale, fn ->
      Gettext.dgettext(
        CourtbotWeb.Gettext,
        "response",
        "OK. We will stop sending reminders for %{case_number}.",
        case_number: case_number
      )
    end)
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

  defp response(:no_subscriptions, _params = %{locale: locale}) do
    Gettext.with_locale(locale, fn ->
      gettext("You are not subscribed to any cases. We won't send you any reminders.")
    end)
  end

  defp response(:hearing_details, params = %{locale: locale, date: _, time: _, first_name: _, last_name: _, county: _}) do
    Gettext.with_locale(locale, fn ->
      Gettext.dgettext(
        CourtbotWeb.Gettext,
        "response",
        "We found a case for %{first_name} %{last_name} in %{county} County. The next hearing is on %{date}, at %{time}.",
        params
      )
    end)
  end

  defp response(:prompt_reminder, _params = %{locale: locale}) do
    Gettext.with_locale(locale, fn ->
      gettext("Would you like a reminder a day before the next hearing date?")
    end)
  end

  defp response(:accept_reminder, params = %{locale: locale, court_url: _}) do
    Gettext.with_locale(locale, fn ->
      Gettext.dgettext(
        CourtbotWeb.Gettext,
        "response",
         "Note that court schedules may change. You should always confirm your hearing date and time by going to %{court_url}",
        params
      )
    end)
  end

  defp response(:reject_reminder, _params = %{locale: locale}) do
    Gettext.with_locale(locale, fn ->
      gettext("You said \"No\" so we won’t text you a reminder.")
    end)
  end

  defp response(
         :reminder,
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
        "This is a reminder for case %{case_number}. The next hearing is %{date}, at %{time}. You can go to %{court_url} for more information.",
        case_number: case_number,
        date: date,
        time: time,
        court_url: court_url
      )
    end)
  end

  defp response(:requires_county, _params = %{locale: locale}) do
    Gettext.with_locale(locale, fn ->
      gettext("Which county are you interested in?")
    end)
  end

  defp response(:not_found, params = %{locale: locale, case_number: _}) do
    Gettext.with_locale(locale, fn ->
      Gettext.dgettext(
        CourtbotWeb.Gettext,
        "response",
        "We did not find case %{case_number} in that county. Please check your case number and county.",
        params
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

  defp response(:help, _params = %{locale: locale}) do
    Gettext.with_locale(locale, fn ->
      gettext("Reply with a case number to sign up for a reminder. For example a case number looks like: CR01-18-22672")
    end)
  end
end
