defmodule Courtbot.Notify do
  alias Courtbot.{
    Case,
    Configuration,
    Hearing,
    Integrations.Twilio,
    Notification,
    Repo,
    Subscriber
  }

  alias CourtbotWeb.Response

  import Ecto.Query

  require Logger

  def run() do
    Logger.info("Starting batches of notifications")

    %{
      locales: locales,
      notifications: %{reminders: reminders},
      twilio: twilio
    } = Configuration.get([:locales, :notifications, :twilio])

    Enum.map(reminders, &(Enum.each(&1, fn({timescale, offset}) ->
      date = Timex.shift(Date.utc_today(), [{String.to_atom(timescale), offset}])

      with pending when pending != [] <- notifications_for_day(date) do
        pending
        |> Enum.chunk_every(100)
        |> Enum.with_index()
        |> Enum.map(fn {notifications, batch} ->
          SchedEx.run_at(Courtbot.Notify, :notify_subscriber_list, [notifications, locales, twilio], Timex.shift(DateTime.utc_now(), seconds: 100 * batch))
        end)
      end
    end)))

    notify_debug_subscribers(locales, twilio)

    Logger.info("Finished starting batches of notifications")
  end

  def notify_subscriber_list(notifications, locales, twilio_credentials) do
    Enum.each(notifications, fn %{case: case, phone_number: phone_number, id: subscriber_id, locale: locale} ->
       twilio = Twilio.new(twilio_credentials)
       from_number = Map.fetch!(locales, locale)
       body = Response.get_message({:remind, case}, locale)

       with {:ok, _result = %Tesla.Env{status: 201}} <- Twilio.message(twilio, %{From: from_number, To: phone_number, Body: body}) do
         %Notification{}
         |> Notification.changeset(%{subscriber_id: subscriber_id})
         |> Repo.insert()
       else
         {:ok, %Tesla.Env{status: status, body: body}} ->
           Logger.error("Unable to notify subscribers. Request to Twilio failed with #{status} and code #{body["code"]}")
         {:error, _} ->
           Logger.error("Unable to send request to Twilio to notify subscribers")
       end
    end)
  end

  def notify_debug_subscribers(locales, twilio_credentials) do
    Logger.info("Sending debug notifications")

    # Notify debug subscribers
    %Case{id: case_id} = Case.find_with([case_number: "beepboop"])

    Enum.map(Subscriber.subscribers_to_case(case_id), fn subscriber ->
      Twilio.message(Twilio.new(twilio_credentials), %{From: Map.fetch!(locales, "en"), To: subscriber.phone_number, Body: "BEEPBOOP"})
    end)
  end

  def notifications_for_day(day) do
    notified =
      from(
        n in Notification,
        where: n.inserted_at >= ^Timex.beginning_of_day(DateTime.utc_now()),
        where: n.inserted_at <= ^Timex.end_of_day(DateTime.utc_now()),
        select: n.subscriber_id
      )

    %Case{id: debug_case_id} = Case.find_with([case_number: "beepboop"])

    from(
      s in Subscriber,
      join: c in Case,
      on: s.case_id == c.id and c.id != ^debug_case_id,
      join: h in Hearing,
      on: h.case_id == s.case_id,
      left_join: n in subquery(notified),
      on: n.subscriber_id == s.id,
      where: is_nil(n.subscriber_id),
      where: h.date == ^day,
      preload: [
        case: [
          hearings: ^from(
            h in Hearing,
            order_by: [h.date, h.time],
            where: h.date >= ^Date.utc_today(),
            limit: 1
          )
        ]
      ]
    )
    |> Repo.all()
  end

end
