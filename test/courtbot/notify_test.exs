defmodule CourtbotTest.NotifyTest do
  use Courtbot.DataCase, asyc: false

  alias Courtbot.{Case, Configuration, Hearing, Notify, Repo, Notification, Subscriber}

  import Ecto.Query

  # Global mock as we have SchedEx sending notifications in a different process.
  setup_all do
    Tesla.Mock.mock_global(fn
      %{method: :post} ->
        %Tesla.Env{status: 201}
    end)

    :ok
  end

  setup do
    Repo.insert!(CourtbotTest.Helper.Configuration.idaho())

    :ok
  end

  defp day(start, timezone, offset) do
    {:ok, today} = DateTime.shift_zone(start, timezone, Tzdata.TimeZoneDatabase)
    Timex.shift(today, offset)
  end

  test "given subscribers there should be one pending notification" do
    cases = %{
      case_today:
        %Case{}
        |> Case.changeset(%{
          case_number: "CR01-16-00001",
          county: "valid",
          type: "criminal",
          parties: [
            %{first_name: "John", last_name: "Doe"}
          ],
          hearings: [
            %{time: ~T[09:00:00], date: Date.add(Date.utc_today(), -1)},
            %{time: ~T[09:00:00], date: Date.utc_today()}
          ]
        })
        |> Repo.insert!(),
      case_tomorrow:
        %Case{}
        |> Case.changeset(%{
          case_number: "CR01-16-00002",
          county: "valid",
          type: "criminal",
          parties: [
            %{first_name: "John", last_name: "Doe"}
          ],
          hearings: [
            %{time: ~T[09:00:00], date: Date.add(Date.utc_today(), 1)},
            %{time: ~T[09:00:00], date: Date.add(Date.utc_today(), 10)}
          ]
        })
        |> Repo.insert!(),
      case_following:
        %Case{}
        |> Case.changeset(%{
          case_number: "CR01-16-00003",
          county: "valid",
          type: "criminal",
          parties: [
            %{first_name: "John", last_name: "Doe"}
          ],
          hearings: [
            %{time: ~T[09:00:00], date: Date.add(Date.utc_today(), 2)},
            %{time: ~T[09:00:00], date: Date.add(Date.utc_today(), 364)}
          ]
        })
        |> Repo.insert!()
    }

    %Subscriber{}
    |> Subscriber.changeset(%{
      case_id: cases.case_today.id,
      phone_number: "12025550170",
      locale: "en"
    })
    |> Repo.insert!()

    %Subscriber{}
    |> Subscriber.changeset(%{
      case_id: cases.case_tomorrow.id,
      phone_number: "12025550170",
      locale: "en"
    })
    |> Repo.insert!()

    %Subscriber{}
    |> Subscriber.changeset(%{
      case_id: cases.case_following.id,
      phone_number: "12025550170",
      locale: "en"
    })
    |> Repo.insert!()

    %{timezone: timezone} = Configuration.get([:timezone])
    tomorrow = day(DateTime.utc_now(), timezone, days: 1)

    pending_notifications = Notify.reminders_for_day(tomorrow)

    assert length(pending_notifications) === 1

    Notify.run()

    Process.sleep(500)

    assert length(Repo.all(from(n in Notification))) === 1
  end

  test "queued for day" do
    case =
      %Case{}
      |> Case.changeset(%{
        case_number: "CR01-16-00004",
        county: "valid",
        type: "criminal",
        parties: [
          %{first_name: "John", last_name: "Doe"}
        ]
      })
      |> Repo.insert!()

    %Subscriber{}
    |> Subscriber.changeset(%{
      case_id: case.id,
      phone_number: "12025550170",
      locale: "en",
      queued: true
    })
    |> Repo.insert!()

    %{timezone: timezone} = Configuration.get([:timezone])
    today = day(DateTime.utc_now(), timezone, days: 0)

    pending_notifications = Notify.queued_subscribers(today)

    assert length(pending_notifications) === 0

    Repo.insert(
      Hearing.changeset(%Hearing{}, %{
        time: ~T[09:00:00],
        date: Date.add(Date.utc_today(), 5),
        case_id: case.id
      })
    )

    pending_notifications = Notify.queued_subscribers(today)

    assert length(pending_notifications) === 1

    Notify.run()

    Process.sleep(500)

    [%Notification{subscriber: %Subscriber{case: %Case{id: case_id}}}] =
      Repo.all(from(n in Notification, preload: [subscriber: :case]))

    assert case_id === case.id

    # Check that you got the queued notification
    assert length(Repo.all(from(n in Notification))) === 1

    # Rerun the notify to check if you get that you don't get another notification
    Notify.run()

    Process.sleep(500)

    assert length(Repo.all(from(n in Notification))) === 1
  end

  test "debug case" do
    debug_case = Repo.insert!(CourtbotTest.Helper.Case.debug_case())

    assert length(Repo.all(from(n in Notification))) === 0

    %Subscriber{}
    |> Subscriber.changeset(%{
      case_id: debug_case.id,
      phone_number: "12025550170",
      locale: "en"
    })
    |> Repo.insert!()

    Notify.run()

    Process.sleep(500)

    [%Notification{subscriber: %Subscriber{case: %Case{id: case_id}}}] =
      Repo.all(from(n in Notification, preload: [subscriber: :case]))

    assert case_id === debug_case.id

    assert length(Repo.all(from(n in Notification))) === 1
  end

  test "debug case isn't included in either the queued or subscriber counts" do
    Repo.insert!(CourtbotTest.Helper.Case.debug_case())

    %{timezone: timezone} = Configuration.get([:timezone])

    today = day(DateTime.utc_now(), timezone, days: 0)
    pending_notifications = Notify.queued_subscribers(today)

    assert length(pending_notifications) === 0

    tomorrow = day(DateTime.utc_now(), timezone, days: 1)
    pending_notifications = Notify.reminders_for_day(tomorrow)

    assert length(pending_notifications) === 0
  end
end
