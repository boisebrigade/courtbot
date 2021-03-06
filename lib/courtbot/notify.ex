defmodule Courtbot.Notify do
  @moduledoc false
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

  def run() do
    Rollbax.report_message(:info, "Starting batches of notifications")

    configuration =
      %{
        locales: _,
        notifications: %{reminders: reminders},
        twilio: _,
        timezone: _
      } = Configuration.get([:locales, :notifications, :twilio, :timezone])

    Enum.map(
      reminders,
      &Enum.each(&1, fn {timescale, offset} ->
        day = get_day(configuration.timezone, {String.to_atom(timescale), offset})

        notify(configuration, :remind, reminders_for_day(day))
      end)
    )

    day = get_day(configuration.timezone)

    notify(configuration, :queued, queued_subscribers(day))

    with %Case{id: case_id} <- Case.find_with(case_number: "beepboop") do
      notify(configuration, :debug, Subscriber.subscribers_to_case(case_id, [:case]))
    end

    Rollbax.report_message(:info, "Finished starting batches of notifications")
  end

  def notify(configuration, type, pending_notification) do
    with pending when pending != [] <- pending_notification do
      pending
      |> batch_notifications()
      |> Enum.map(fn {notifications, batch} ->
        SchedEx.run_at(
          Courtbot.Notify,
          :send_twilio_notification,
          [notifications, configuration, type],
          Timex.shift(DateTime.utc_now(), seconds: 100 * batch)
        )
      end)
    else
      _ -> Rollbax.report_message(:warning, "Notification queue for #{type} is empty")
    end
  end

  def get_day(timezone, offset \\ {:hours, 0}) do
    {:ok, today} = DateTime.shift_zone(DateTime.utc_now(), timezone, Tzdata.TimeZoneDatabase)
    Timex.shift(today, [offset])
  end

  def send_twilio_notification(
        notifications,
        %{locales: locales, twilio: twilio_credentials},
        type
      ) do
    Enum.each(
      notifications,
      fn subscriber = %{case: case, phone_number: phone_number, id: subscriber_id, locale: locale} ->
        from_number = Map.fetch!(locales, locale)
        body = Response.get_message({type, case}, locale)

        twilio_response =
          Twilio.new(twilio_credentials)
          |> Twilio.message(%{From: from_number, To: phone_number, Body: body})

        with {:ok, _result = %Tesla.Env{status: 201}} <- twilio_response do
          %Notification{}
          |> Notification.changeset(%{
            subscriber_id: subscriber_id,
            message: body,
            type: Atom.to_string(type)
          })
          |> Repo.insert!()

          Subscriber.changeset(subscriber, %{queued: false}) |> Repo.update!()
        else
          {:ok, %Tesla.Env{status: status, body: body}} ->
            Rollbax.report_message(
              :error,
              "Unable to notify subscribers. Request to Twilio failed with #{status} and code #{
                body["code"]
              }"
            )

          {:error, _} ->
            Rollbax.report_message(
              :error,
              "Unable to send request to Twilio to notify subscriber: #{subscriber_id}"
            )
        end
      end
    )
  end

  def reminders_for_day(day) do
    notified =
      from(
        n in Notification,
        where: n.inserted_at >= ^Timex.beginning_of_day(day),
        where: n.inserted_at <= ^Timex.end_of_day(day),
        where: n.type == "remind",
        select: n.subscriber_id
      )

    latest_hearing =
      from(
        h in Hearing,
        order_by: [h.date, h.time],
        where: h.date >= ^day,
        limit: 1
      )

    from(
      s in Subscriber,
      join: c in Case,
      on: s.case_id == c.id,
      join: h in Hearing,
      on: h.case_id == s.case_id,
      left_join: n in subquery(notified),
      on: n.subscriber_id == s.id,
      where: is_nil(n.subscriber_id),
      where: h.date == ^day,
      preload: [
        case: [{:hearings, ^latest_hearing}, :parties]
      ]
    )
    |> Repo.all()
  end

  def queued_subscribers(day) do
    latest_hearing =
      from(
        h in Hearing,
        order_by: [h.date, h.time],
        where: h.date >= ^day,
        limit: 1
      )

    from(
      s in Subscriber,
      where: s.queued == true,
      join: c in Case,
      on: s.case_id == c.id,
      join: h in Hearing,
      on: h.case_id == s.case_id,
      preload: [
        case: [{:hearings, ^latest_hearing}, :parties]
      ]
    )
    |> Repo.all()
  end

  defp batch_notifications(pending) do
    pending
    |> Enum.chunk_every(100)
    |> Enum.with_index()
  end
end
