defmodule ExCourtbot.TwilioController do
  use ExCourtbotWeb, :controller

  alias ExCourtbotWeb.{Case, Subscriber}

  def index(conn, _) do
    conn
    |> send_resp(200, "Ok")
  end

  def sms(conn, %{"From" => phone_number, "Body" => body}) do
    message = body
    |> String.downcase()

    unsubscribe_keywords = [gettext("stop"), gettext("stopall"), gettext("cancel"), gettext("end"), gettext("quit"), gettext("unsubscribe")]

    cond do
      Enum.member?(unsubscribe_keywords, message) -> handle_unsubscribe(conn, phone_number)
      true -> handle_reponse(conn, phone_number, body |> clean_case_number)
    end
  end

  def sms(conn, _) do
    conn
    |> send_resp(400, "Ok")
  end

  defp clean_case_number(case_number) do
    case_number
    |> String.strip
    |> String.downcase
    |> String.replace("-", "")
    |> String.replace("_", "")
    |> String.replace(",", "")
  end

  defp handle_reponse(conn, phone_number, case_number) do
    result = Case.find(case_number)

    case result do
      [%Case{hearings: []}] -> prompt_no_hearings(conn)
      [%Case{hearings: hearing}] -> prompt_remind(conn, hearing)
      [_|_] -> prompt_county(conn, result)
      _ -> prompt_unfound(conn, phone_number, case_number)
    end
  end

  defp handle_unsubscribe(conn, phone_number) do
    "Unsub" |> IO.inspect
    Subscriber.unsubscribe(phone_number)

    conn
    |> send_resp(200, "Ok")
  end

  defp prompt_no_hearings(conn) do
    "No hearings found" |> IO.inspect

    conn
    |> send_resp(200, "Ok")
  end

  defp prompt_unfound(conn, phone_number, case_number) do
    "Not found" |> IO.inspect
    conn
    |> send_resp(200, "Ok")
  end

  defp prompt_remind(conn, _) do
    "Remind" |> IO.inspect
    conn
    |> send_resp(200, "Ok")
  end

  defp prompt_county(conn, case_number) do
    "County" |> IO.inspect

    conn
    |> put_session(:requires_county, case_number)

    # TODO(ts): Does it make sense to include which counties we've found?
    gettext """
      Multiple cases found with this case number. Which county are you interested in?
    """
  end

  defp subscribe(conn, phone_number, case_number) do
    "Sub" |> IO.inspect

    conn
    |> put_session(:has_subscribed, true)
    |> send_resp(200, "Ok")
  end

  defp encode_twilio(conn, message) do
    conn
    |> put_resp_header("Content-Type", "application/xml")
  end

end
