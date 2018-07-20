defmodule ExCourtbotWeb.Response do
  import ExCourtbotWeb.Gettext

  def message(:unsubscribe, %{"locale" => locale}) do
    Gettext.with_locale(locale, fn ->
      gettext("OK. We will stop sending reminders.")
    end)
  end

  def message(:no_subscriptions, %{"locale" => locale}) do
    Gettext.with_locale(locale, fn ->
      gettext("You are currently not subscribed to any cases. We won't send you any reminders.")
    end)
  end

  def message(:hearing_details, %{"locale" => locale, "date" => date, "time" => time}) do
    time_formated = time |> Time.truncate(:second) |> Time.to_string
    date_formated = Date.to_string(date)

    Gettext.with_locale(locale, fn ->
      Gettext.dgettext(ExCourtbotWeb.Gettext, "response", "The next hearing is tomorrow, %{date}, at %{time}", [date: date_formated, time: time_formated])
    end)
  end

  def message(:prompt_reminder, %{"locale" => locale}) do
    Gettext.with_locale(locale, fn ->
      gettext("Would you like a reminder 24hr before your hearing date?")
    end)
  end

  def message(:accept_reminder, %{"locale" => locale}) do
    Gettext.with_locale(locale, fn ->
      gettext(
        "OK. We will text you a courtesy reminder the day before your hearing date. Note that court schedules frequently change."
      )
    end)
  end

  def message(:reject_reminder, %{"locale" => locale}) do
    Gettext.with_locale(locale, fn ->
      gettext("You said “No” so we won’t text you a reminder.")
    end)
  end

  def message(:reminder, %{"locale" => locale, "case_number" => case_number, "date" => date, "time" => time}) do
    time_formated = time |> Time.truncate(:second) |> Time.to_string
    date_formated = Date.to_string(date)

    Gettext.with_locale(locale, fn ->
      Gettext.dgettext(ExCourtbotWeb.Gettext, "response", "This is a reminder for case %{case_number}. The next hearing is tomorrow, %{date}, at %{time}", [case_number: case_number, date: date_formated, time: time_formated])
    end)
  end

  def message(:requires_county, %{"locale" => locale}) do
    # TODO(ts): Does it make sense to include which counties we've found?
    Gettext.with_locale(locale, fn ->
      gettext("Multiple cases found with this case number. Which county are you interested in?")
    end)
  end

  def message(:no_county, %{"locale" => locale}) do
    Gettext.with_locale(locale, fn ->
      gettext("We do not have case information for that county")
    end)
  end

  def message(:no_hearings, %{"locale" => locale}) do
    Gettext.with_locale(locale, fn ->
      gettext(
        "We currently have no details about any upcoming hearings for this case. Would you like a reminder if we receive details?"
      )
    end)
  end

  def message(:not_found, %{"locale" => locale}) do
    Gettext.with_locale(locale, fn ->
      gettext(
        "Reply with a case or ticket number to sign up for a reminder. For example a case number looks like: CR01-18-22672"
      )
    end)
  end

  def message(:yes_or_no, %{"locale" => locale}) do
    Gettext.with_locale(locale, fn ->
      gettext("Sorry, didn't understand. Would you like a reminder about the hearing? Yes or No")
    end)
  end
end
