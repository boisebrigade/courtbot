defmodule CourtbotWeb.Response do
  @moduledoc """
  Provides `message/2` to provide responses based upon the type given and the params avaliable
  """

  import CourtbotWeb.Gettext

  @date_format "%m/%d/%Y"
  @time_format "%I:%M %p"

  def message(type, params) do
    # Add config values to our params so our response can vary based on settings.
    config =
      Application.get_env(:courtbot, Courtbot, %{})
      |> Map.new()
      |> Map.take([:court_url, :queued_ttl_days, :subscribe_limit])

    response(type, Map.merge(config, params))
  end

  defp response(:unsubscribe, %{"locale" => locale}) do
    Gettext.with_locale(locale, fn ->
      gettext("OK. We will stop sending reminders for all cases you are subscribed to.")
    end)
  end

  defp response(:unsubscribe, %{"locale" => locale, "case_number" => case_number}) do
    Gettext.with_locale(locale, fn ->
      Gettext.dgettext(
        CourtbotWeb.Gettext,
        "response",
        "OK. We will stop sending reminders for %{case_number}.",
        case_number: case_number
      )
    end)
  end

  defp response(:already_subscribed, %{"locale" => locale}) do
    Gettext.with_locale(locale, fn ->
      gettext(
        "You are already subscribed to this case. To unsubscribe to this case reply with DELETE."
      )
    end)
  end

  defp response(:resubscribe, %{"locale" => locale}) do
    Gettext.with_locale(locale, fn ->
      gettext("You will need to resubscribe to the case to receive hearing reminders.")
    end)
  end

  defp response(:no_subscriptions, %{"locale" => locale}) do
    Gettext.with_locale(locale, fn ->
      gettext("You are not subscribed to any cases. We won't send you any reminders.")
    end)
  end

  defp response(:hearing_details, %{"locale" => locale, "date" => date, "time" => time}) do
    time_formated = Timex.format!(time, @time_format, :strftime)
    date_formated = Timex.format!(date, @date_format, :strftime)

    Gettext.with_locale(locale, fn ->
      Gettext.dgettext(
        CourtbotWeb.Gettext,
        "response",
        "The next hearing is on %{date}, at %{time}.",
        date: date_formated,
        time: time_formated
      )
    end)
  end

  defp response(:prompt_reminder, %{"locale" => locale}) do
    Gettext.with_locale(locale, fn ->
      gettext("Would you like a reminder a day before the next hearing date?")
    end)
  end

  defp response(:accept_reminder, %{"locale" => locale}) do
    Gettext.with_locale(locale, fn ->
      gettext("OK. We will text you a courtesy reminder the day before the hearing date.")
    end)
  end

  defp response(:accept_reminder, %{"locale" => locale, :court_url => court_url}) do
    Gettext.with_locale(locale, fn ->
      gettext(
        "Note that court schedules may change. You should always confirm your hearing date and time by going to %{court_url}"
      )
    end)
  end

  defp response(:reject_reminder, %{"locale" => locale}) do
    Gettext.with_locale(locale, fn ->
      gettext("You said “No” so we won’t text you a reminder.")
    end)
  end

  defp response(:reminder, %{
         "locale" => locale,
         "case_number" => case_number,
         "date" => date,
         "time" => time,
         :court_url => court_url
       }) do
    time_formated = Timex.format!(time, @time_format, :strftime)
    date_formated = Timex.format!(date, @date_format, :strftime)

    Gettext.with_locale(locale, fn ->
      Gettext.dgettext(
        CourtbotWeb.Gettext,
        "response",
        "This is a reminder for case %{case_number}. The next hearing is on %{date}, at %{time}. You can go to %{court_url} for more information.",
        case_number: case_number,
        date: date_formated,
        time: time_formated,
        court_url: court_url
      )
    end)
  end

  defp response(:reminder, %{
         "locale" => locale,
         "case_number" => case_number,
         "date" => date,
         "time" => time
       }) do
    time_formated = Timex.format!(time, @time_format, :strftime)
    date_formated = Timex.format!(date, @date_format, :strftime)

    Gettext.with_locale(locale, fn ->
      Gettext.dgettext(
        CourtbotWeb.Gettext,
        "response",
        "This is a reminder for case %{case_number}. The next hearing is tomorrow, %{date}, at %{time}.",
        case_number: case_number,
        date: date_formated,
        time: time_formated
      )
    end)
  end

  defp response(:requires_county, %{"locale" => locale}) do
    Gettext.with_locale(locale, fn ->
      gettext("Which county are you interested in?")
    end)
  end

  defp response(:no_county, %{"locale" => locale}) do
    Gettext.with_locale(locale, fn ->
      gettext("We do not have case information for that county")
    end)
  end

  defp response(:no_hearings, %{"locale" => locale}) do
    Gettext.with_locale(locale, fn ->
      gettext(
        "We currently have no details about any upcoming hearings for this case. Would you like a reminder if we receive details?"
      )
    end)
  end

  defp response(:not_found, %{"locale" => locale}) do
    Gettext.with_locale(locale, fn ->
      gettext(
        "We didn't find case %{case_number} in that county. Please check your case number and county."
      )
    end)
  end

  defp response(:yes_or_no, %{"locale" => locale}) do
    Gettext.with_locale(locale, fn ->
      gettext(
        "Sorry, I didn't understand. Would you like a courtesy reminder a day before the hearing? Reply YES or NO"
      )
    end)
  end

  defp response(:standard, %{"locale" => locale}) do
    Gettext.with_locale(locale, fn ->
      gettext(
        "Reply with a case number to sign up for a reminder. For example: CR01-18-22672"
      )
    end)
  end
end
