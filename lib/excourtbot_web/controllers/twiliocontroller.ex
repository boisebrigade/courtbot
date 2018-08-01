defmodule ExCourtbot.TwilioController do
  use ExCourtbotWeb, :controller

  require Logger

  alias ExCourtbot.Repo
  alias ExCourtbotWeb.{Response, Case, Twiml, Subscriber}

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

  @request_defaults %{"locale" => "en"}

  def sms(conn, params = %{"From" => phone_number, "Body" => body}) do
    %Plug.Conn{private: %{plug_session: session}} = conn

    # Preprocess our SMS message to make it a bit friendier to use.
    message =
      body
      |> String.trim()
      |> String.downcase()

    # Add our defaults, SMS details, and santized message.
    request =
      Enum.reduce([@request_defaults, params, session, %{"message" => message}], fn m, acc ->
        Map.merge(m, acc)
      end)

    # If the user wants to unsubscribe handle that up front.
    cond  do
      Enum.member?(@unsubscribe_keywords, message) ->
        Logger.info(log_safe_phone_number(phone_number) <> ": Unsubscribing")

        subscriptions = Subscriber.find_by_number(phone_number) |> Repo.all()

        response =
          if Enum.empty?(subscriptions) do
            Response.message(:no_subscriptions, request)
          else
            Repo.delete_all(Subscriber.find_by_number(phone_number))
            Response.message(:unsubscribe, request)
          end

        conn
        |> clear_session
        |> encode(response)
      message == "start" ->
        Logger.info(log_safe_phone_number(phone_number) <> ": Unsubscribing")

        response = Response.message(:resubscribe, request)

        conn
        |> clear_session
        |> encode(response)
      true -> respond(conn, request)
    end
  end

  # If we've previously asked them for a county.
  defp respond(
         conn,
         params = %{
           "From" => phone_number,
           "message" => message,
           "requires_county" => case_number
         }
       ) do
    result = Case.find_with_county(case_number, message)

    if Enum.member?(Case.all_counties(), message) do
      case_response(conn, params, result)
    else
      Logger.warn(log_safe_phone_number(phone_number) <> ": No county data for #{case_number}")

      response = Response.message(:no_county, params)

      conn
      |> clear_session
      |> encode(response)
    end
  end

  # If we've asked them if they would like a reminder
  defp respond(
         conn,
         params = %{
           "From" => phone_number,
           "Body" => body,
           "message" => message,
           "locale" => locale,
           "reminder" => case_id
         }
       ) do
    cond do
      Enum.member?(@accept_keywords, message) ->
        Logger.info(log_safe_phone_number(phone_number) <> ": Subscribing")

        %Subscriber{}
        |> Subscriber.changeset(%{case_id: case_id, phone_number: phone_number, locale: locale})
        |> Repo.insert()

        response = Response.message(:accept_reminder, params)

        conn
        |> clear_session
        |> encode(response)

      Enum.member?(@reject_keywords, message) ->
        Logger.info(log_safe_phone_number(phone_number) <> ": Rejected reminder offer")

        response = Response.message(:reject_reminder, params)

        conn
        |> clear_session
        |> encode(response)

      true ->
        Logger.warn("Unknown reply #{body}")

        response = Response.message(:yes_or_no, params)

        conn
        |> encode(response)
    end
  end

  # Typical first time messaging the service
  defp respond(conn, params = %{"message" => message}) do
    result = Case.find_by_case_number(clean_case_number(message))

    case_response(conn, params, result)
  end

  defp case_response(conn, params, result) do
    case result do
      [case = %Case{hearings: []}] -> prompt_no_hearings(conn, params, case)
      [case = %Case{hearings: _}] -> prompt_remind(conn, params, case)
      [_ | _] -> prompt_county(conn, params)
      _ -> prompt_unfound(conn, params)
    end
  end

  defp prompt_no_hearings(conn, params = %{"From" => phone_number}, case) do
    Logger.warn(
      log_safe_phone_number(phone_number) <>
        ": No hearings found for case number: #{case.case_number}"
    )

    response = Response.message(:no_hearings, params)

    conn
    |> put_session(:reminder, case.id)
    |> encode(response)
  end

  defp prompt_unfound(conn, params = %{"From" => phone_number, "message" => message}) do
    Logger.warn(log_safe_phone_number(phone_number) <> ": No case found for input: #{message}")

    response = Response.message(:not_found, params)

    conn
    |> clear_session
    |> encode(response)
  end

  defp prompt_remind(conn, params = %{"From" => phone_number}, case) do
    Logger.info(log_safe_phone_number(phone_number) <> ": Asking about reminder")

    %ExCourtbotWeb.Case{
      first_name: first_name,
      last_name: last_name,
      hearings: [
        %ExCourtbotWeb.Hearing{
          time: time,
          date: date,
          location: location
        }
      ]
    } = case

    response =
      Response.message(
        :hearing_details,
        Map.merge(params, %{
          "first_name" => first_name,
          "last_name" => last_name,
          "date" => date,
          "time" => time,
          "location" => location
        })
      ) <> " " <> Response.message(:prompt_reminder, params)

    conn
    |> put_session(:reminder, case.id)
    |> encode(response)
  end

  defp prompt_county(conn, params = %{"From" => phone_number, "message" => case_number}) do
    Logger.info(log_safe_phone_number(phone_number) <> ": Asking about county")

    response = Response.message(:requires_county, params)

    conn
    |> put_session(:requires_county, case_number)
    |> encode(response)
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

  defp encode(conn, response) do
    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, Twiml.sms(response))
  end
end
