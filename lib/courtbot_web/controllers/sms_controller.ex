defmodule CourtbotWeb.SmsController do
  @moduledoc false

  use CourtbotWeb, :controller

  alias Courtbot.{Idempotent, Notification, Repo, Workflow}
  alias CourtbotWeb.{Response, Twiml}

  import Ecto.Query

  require Logger

  def twilio(
        conn = %Plug.Conn{private: %{plug_session: session}},
        _params = %{"From" => phone_number, "Body" => body, "locale" => locale}
      ) do
    # Normalize the structure coming in after being loaded from session. All keys *should* be atoms already and if they
    # are not then it's likely junk data being sent to us.
    %{properties: properties, state: state, input: input} =
      case session do
        %{"properties" => properties, "state" => state, "input" => input} ->
          properties =
            for {key, val} <- properties, into: %{}, do: {String.to_existing_atom(key), val}

          input = for {key, val} <- input, into: %{}, do: {String.to_existing_atom(key), val}

          %{properties: properties, state: String.to_existing_atom(state), input: input}
          
        %{} ->
          %{properties: %{}, state: :inquery, input: %{}}
      end

    input = Map.put(input, state, body)

    body = normalize_input(body)

    try do
      {response, _fsm = %Courtbot.Workflow{state: state, properties: properties, input: input}} =
        Workflow.init(%Workflow{
          counties: true,
          types: true,
          locale: locale,
          state: state,
          properties: properties,
          input: input
        })
        |> Workflow.message(from: phone_number, body: body)
        |> Response.get_message()

      conn =
        if state === :inquery do
          conn
          |> configure_session(drop: true)
          |> delete_resp_cookie("_courtbot_key")
        else
          conn
          |> put_session(:state, state)
          |> put_session(:properties, properties)
          |> put_session(:input, input)
        end

      encode_for_twilio(conn, response)
    rescue
      e ->
        Logger.error(Exception.format(:error, e, __STACKTRACE__))

        # TODO(ts): Courtbot should send something here to the end user.
        conn
        |> configure_session(drop: true)
        |> send_resp(:internal_server_error, "")
    end
  end

  defp normalize_input(input) do
    input
    |> String.trim()
    |> String.replace("-", "")
    |> String.replace("_", "")
    |> String.replace(",", "")
    |> String.downcase()
  end

  def status(conn, params = %{"notificationId" => notification_id}) do
    notification = from(n in Notification, where: n.id == ^notification_id) |> Repo.one()

    case notification do
      %Notification{} ->
        Notification.changeset(notification, %{status: params["MessageStatus"]}) |> Repo.update()

      _ ->
        Logger.error("Notification passed to status is invalid: #{notification_id}")
    end

    # FIXME(ts): Re-enqueue these to be sent.
    case params["MessageStatus"] do
      "undelivered" -> Logger.error("#{notification_id} went undelivered")
      "failed" -> Logger.error("#{notification_id} failed to be delivered")
      _ -> nil
    end

    conn
    |> send_resp(:ok, "")
  end

  def usage(conn, params) do
    # Check if we already have a token
    with token <- Idempotent.get(params["UsageTriggerSid"]) do
      # Check if this is a unique invocation of the usage alert. If it is alert, if not then we ignore
      if params["IdempotencyToken"] !== token do
        Idempotent.put(params["UsageTriggerSid"], params["IdempotencyToken"])

        send_usage_alert(params)
      end
    end

    conn
    |> send_resp(:ok, "")
  end

  defp send_usage_alert(params) do
    :alarm_handler.set_alarm(
      {:usage_alert,
       %{
         time_period: params["Recurring"],
         trigger_value: params["TriggerValue"],
         current_value: params["CurrentValue"]
       }}
    )
  end

  defp encode_for_twilio(conn, response) do
    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(:ok, Twiml.sms(response))
  end
end
