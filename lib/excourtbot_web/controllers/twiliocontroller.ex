defmodule ExCourtbot.TwilioController do
  use ExCourtbotWeb, :controller

  require Logger

  alias ExCourtbot.Repo
  alias ExCourtbotWeb.{Case, Subscriber}

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

  @unsubscribe_keywords [
    gettext("stop"),
    gettext("stopall"),
    gettext("cancel"),
    gettext("end"),
    gettext("quit"),
    gettext("unsubscribe")
  ]

  def index(conn, _) do
    conn
    |> send_resp(200, "Ok")
  end

  def sms(conn = %Plug.Conn{private: %{plug_session: session}}, %{
        "From" => phone_number,
        "Body" => body
      })
      when is_map(session) and session != %{} do

    message =
      body
      |> String.trim()
      |> String.downcase()

    # Handle multiple step cases
    session
    |> case do
      %{"requires_county" => case_number} ->
        result = Case.find_with_county(case_number, message)
        handle_reponse(conn, phone_number, result, case_number)

      %{"reminder" => case_number} -> cond do
         Enum.member?(@accept_keywords, message) -> handle_subscribe(conn, phone_number, case_number)
         Enum.member?(@reject_keywords, message) -> Logger.warn("Rejected reminder offer")
         true -> Logger.error("Unknown reply #{body}")
      end

      _ ->
        Logger.error("State unknown")
    end
  end

  def sms(conn, %{"From" => phone_number, "Body" => body}) do
    message =
      body
      |> String.trim()
      |> String.downcase()

    cond do
      Enum.member?(@unsubscribe_keywords, message) -> handle_unsubscribe(conn, phone_number)
      true -> handle_reponse(conn, phone_number, body |> clean_case_number |> Case.find_by_case_number(), body)
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

  defp handle_reponse(conn, phone_number, result, case_number) do
    case result do
      [case = %Case{hearings: []}] -> prompt_no_hearings(conn, phone_number, case)
      [case = %Case{hearings: hearing}] -> prompt_remind(conn, phone_number, case)
      [_ | _] -> prompt_county(conn, phone_number, case_number)
      _ -> prompt_unfound(conn, phone_number, case_number)
    end
  end

  defp handle_unsubscribe(conn, phone_number) do
    Logger.info(log_safe_phone_number(phone_number) <> ": Unsubscribing")

    Subscriber.unsubscribe(phone_number)
    |> Repo.update()

    conn
    |> send_resp(200, "Ok")
  end

  defp handle_subscribe(conn, phone_number, case_id) do
    Logger.info(log_safe_phone_number(phone_number) <> ": Subscribing")

    %Subscriber{}
    |> Subscriber.changeset(%{case_id: case_id, phone_number: phone_number})
    |> Repo.insert

    conn
    |> send_resp(200, "Ok")
  end

  defp prompt_no_hearings(conn, phone_number, case) do
    Logger.warn(
      log_safe_phone_number(phone_number) <> ": No hearings found for case number: #{case.case_number}"
    )

    response =
      "We were unable to find any hearing information for that case number. Look at xyz.com website to follow the case." |> gettext

    conn
    |> encode_twilio(response)
  end

  defp prompt_unfound(conn, phone_number, case_number) do
    Logger.warn(log_safe_phone_number(phone_number) <> ": No case found: #{case_number}")

    response =
      "Unable to find your case number:" |> gettext

    conn
    |> encode_twilio(response <> " #{case_number}")
  end

  defp prompt_remind(conn, phone_number, case) do
    Logger.info(log_safe_phone_number(phone_number) <> ": Asking about reminder")

    response =
      "Would you like a reminder 24hr before your hearing date?" |> gettext

    conn
    |> put_session(:reminder, case.id)
    |> encode_twilio(response)
  end

  defp prompt_county(conn, phone_number, case_number) do
    Logger.info(log_safe_phone_number(phone_number) <> ": Asking about county")

    # TODO(ts): Does it make sense to include which counties we've found?
    response =
      "Multiple cases found with this case number. Which county are you interested in?" |> gettext

    conn
    |> put_session(:requires_county, case_number)
    |> encode_twilio(response)
  end

  defp encode_twilio(conn, message) do
    conn
    |> put_resp_header("content-type", "application/xml")
    |> send_resp(200, message)
  end
end
