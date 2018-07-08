defmodule ExCourtbot.TwilioController do
  use ExCourtbotWeb, :controller

  require Logger

  alias ExCourtbotWeb.{Case, Subscriber}

  def index(conn, _) do
    conn
    |> send_resp(200, "Ok")
  end

  def sms(conn = %Plug.Conn{private: %{plug_session: session}}, %{
        "From" => phone_number,
        "Body" => body
      })
      when is_map(session) do
    session
    |> case do
      %{requires_county: case_number} ->
        result = Case.find_with_county(case_number, body)

        result
        |> IO.inspect()

        case result do
          _ -> prompt_unfound(conn, phone_number, case_number)
        end

      _ ->
        Logger.error("State unknown")
    end
  end

  def sms(conn, %{"From" => phone_number, "Body" => body}) do
    message =
      body
      |> String.downcase()

    unsubscribe_keywords = [
      gettext("stop"),
      gettext("stopall"),
      gettext("cancel"),
      gettext("end"),
      gettext("quit"),
      gettext("unsubscribe")
    ]

    cond do
      Enum.member?(unsubscribe_keywords, message) -> handle_unsubscribe(conn, phone_number)
      true -> handle_reponse(conn, phone_number, body |> clean_case_number)
    end
  end

  defp clean_case_number(case_number) do
    case_number
    |> String.trim()
    |> String.downcase()
    |> String.replace("-", "")
    |> String.replace("_", "")
    |> String.replace(",", "")
  end

  defp log_safe_phone_number(phone_number) do
    String.slice(phone_number, -4..-1)
  end

  defp handle_reponse(conn, phone_number, case_number) do
    result = Case.find(case_number)

    case result do
      [%Case{hearings: []}] -> prompt_no_hearings(conn, phone_number, case_number)
      [%Case{hearings: hearing}] -> prompt_remind(conn, phone_number, case_number, hearing)
      [_ | _] -> prompt_county(conn, phone_number, result)
      _ -> prompt_unfound(conn, phone_number, case_number)
    end
  end

  defp handle_unsubscribe(conn, phone_number) do
    Logger.info(log_safe_phone_number(phone_number) <> ": Unsubscribing")

    Subscriber.unsubscribe(phone_number)

    conn
    |> send_resp(200, "Ok")
  end

  defp prompt_no_hearings(conn, phone_number, case_number) do
    Logger.warn(
      log_safe_phone_number(phone_number) <> ": No hearings found for case number: #{case_number}"
    )

    response =
      gettext("""
        We were unable to find any hearing information for that case number. Look at xyz.com website to follow the case.
      """)

    conn
    |> encode_twilio(response)
  end

  defp prompt_unfound(conn, phone_number, case_number) do
    Logger.warn(log_safe_phone_number(phone_number) <> ": No case found: #{case_number}")

    response =
      gettext("""
        Unable to find your case number:
      """)

    conn
    |> encode_twilio(response <> " #{case_number}")
  end

  defp prompt_remind(conn, phone_number, case_number, _) do
    Logger.info(log_safe_phone_number(phone_number) <> ": Asking about reminder")

    response =
      gettext("""
        Would you like a reminder 24hr before your hearing date?
      """)

    conn
    |> put_session(:reminder, case_number)
    |> encode_twilio(response)
  end

  defp prompt_county(conn, phone_number, case_number) do
    Logger.info(log_safe_phone_number(phone_number) <> ": Asking about county")

    # TODO(ts): Does it make sense to include which counties we've found?
    response =
      gettext("""
        Multiple cases found with this case number. Which county are you interested in?
      """)

    conn
    |> put_session(:requires_county, case_number)
    |> encode_twilio(response)
  end

  defp encode_twilio(conn, message) do
    conn
    |> put_resp_header("Content-Type", "application/xml")
    |> send_resp(200, message)
  end
end
