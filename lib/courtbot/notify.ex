defmodule Courtbot.Notify do
  @moduledoc """
  Notification logic.

  Handles the queries for reminders and queued subscribers. Has the logic for batching and sending notifications at
  specific times based on configuration.
  """
  alias Courtbot.{
    Case,
    Configuration,
    Hearing,
    Integrations.Twilio,
    Notification,
    Repo,
    Subscriber
  }

  require Logger

  alias CourtbotWeb.Response

  import Ecto.Query

  def run(), do: run(DateTime.utc_now())

  @doc """

  """
  def run(for_day) do
    Logger.info("Starting batches of notifications")

    configuration =
      %{
        locales: _,
        notifications: %{reminders: reminders},
        twilio: _,
        timezone: _
      } = Configuration.get([:locales, :notifications, :twilio, :timezone])

    Enum.map(
      reminders, fn %{timescale: timescale, offset: offset} ->
        day = get_day(for_day, configuration.timezone, {String.to_atom(timescale), offset})

        notify(configuration, :remind, reminders_for(for_day, day, "#{offset} #{timescale}"), "#{offset} #{timescale}")
      end
    )

    day = get_day(for_day, configuration.timezone)

    notify(configuration, :queued, queued_subscribers(for_day, day))

    with %Case{id: case_id} <- Case.find_with(case_number: "beepboop") do
      notify(configuration, :debug, Subscriber.subscribers_to_case(case_id, [:case]))
    end

    Logger.info("Finished starting batches of notifications")
  end

  @doc """

  """
  def notify(configuration, type, pending_notification, interval \\ nil) do
    with pending when pending != [] <- pending_notification do
      pending
      |> batch_notifications()
      |> Enum.map(fn {notifications, batch} ->
        SchedEx.run_at(
          Courtbot.Notify,
          :send_twilio_notification,
          [notifications, configuration, type, interval],
          Timex.shift(DateTime.utc_now(), seconds: 100 * batch)
        )
      end)
    else
      _ -> Logger.warn("Notification queue for #{type} is empty")
    end
  end

  @doc """

  """
  def get_day(day, timezone, offset \\ {:hours, 0}) do
    {:ok, today} = DateTime.shift_zone(day, timezone, Tzdata.TimeZoneDatabase)

    Timex.shift(today, [offset])
  end

  @doc """

  """
  def send_twilio_notification(
        notifications,
        %{locales: locales, twilio: twilio_credentials},
        type,
        interval
      ) do

    Enum.each(
      notifications,
      fn subscriber = %{case: case, phone_number: phone_number, id: subscriber_id, locale: locale} ->
        from_number = Map.fetch!(locales, locale)
        body = Response.get_message({type, case}, locale)

        notification_id = Ecto.UUID.generate()

        twilio_response =
          Twilio.new(twilio_credentials)
          |> Twilio.send_message(
            %{From: from_number, To: phone_number, Body: body},
            notification_id
          )

        with {:ok, result = %Tesla.Env{status: 201}} <- twilio_response do
          %Notification{}
          |> Notification.changeset(%{
            id: notification_id,
            subscriber_id: subscriber_id,
            message: body,
            type: Atom.to_string(type),
            sid: result.body["sid"],
            interval: interval
          })
          |> Repo.insert!()

          Subscriber.changeset(subscriber, %{queued: false}) |> Repo.update!()
        else
          {:ok, %Tesla.Env{status: status, body: body}} ->
            Logger.error(
              "Unable to notify subscriber. Request to Twilio failed with #{status} and code #{
                body["code"]
              }"
            )

          {:error, _} ->
            Logger.error(
              "Unable to send request to Twilio to notify subscriber: #{subscriber_id}"
            )
        end
      end
    )
  end

  @doc """

  """
  def reminders_for(utc_day, wall_day, interval) do
    notified =
      from(
        n in Notification,
        where: n.inserted_at >= ^Timex.beginning_of_day(utc_day),
        where: n.inserted_at <= ^Timex.end_of_day(utc_day),
        where: n.type == "remind",
        where: n.interval == ^interval
      )

    latest_hearing =
      from(
        h in Hearing,
        order_by: [h.date, h.time],
        where: h.date >= ^wall_day,
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
      where: h.date == ^wall_day,
      distinct: s.id,
      preload: [
        case: [{:hearings, ^latest_hearing}, :parties]
      ]
    )
    |> Repo.all()
  end

  @doc """

  """
  def queued_subscribers(utc_day, wall_day) do
    notified =
      from(
        n in Notification,
        where: n.inserted_at >= ^Timex.beginning_of_day(utc_day),
        where: n.inserted_at <= ^Timex.end_of_day(utc_day),
        where: n.type == "queued"
      )

    latest_hearing =
      from(
        h in Hearing,
        order_by: [h.date, h.time],
        where: h.date > ^wall_day,
        limit: 1
      )

    from(
      s in Subscriber,
      where: s.queued == true,
      join: c in Case,
      on: s.case_id == c.id,
      join: h in Hearing,
      on: h.case_id == s.case_id,
      left_join: n in subquery(notified),
      on: n.subscriber_id == s.id,
      where: is_nil(n.subscriber_id),
      where: h.date > ^wall_day,
      distinct: s.id,
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
