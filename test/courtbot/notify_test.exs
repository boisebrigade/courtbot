defmodule CourtbotTest.NotifyTest do
  use Courtbot.DataCase, asyc: true

  alias Courtbot.{Case, Notify, Repo, Notification, Subscriber}

  import Ecto.Query

  setup do
    Repo.insert!(CourtbotTest.Helper.Configuration.boise())

    case_today =
      %Case{}
      |> Case.changeset(%{
        case_number: "CR01-16-00001",
        county: "valid",
        type: "criminal",
        first_name: "John",
        last_name: "Doe",
        hearings: [
          %{time: ~T[09:00:00], date: Date.add(Date.utc_today(), -1)},
          %{time: ~T[09:00:00], date: Date.utc_today()}
        ]
      })
      |> Repo.insert!()

    case_tomorrow =
      %Case{}
      |> Case.changeset(%{
        case_number: "CR01-16-00002",
        county: "valid",
        type: "criminal",
        first_name: "John",
        last_name: "Doe",
        hearings: [
          %{time: ~T[09:00:00], date: Date.add(Date.utc_today(), 1)},
          %{time: ~T[09:00:00], date: Date.add(Date.utc_today(), 10)}
        ]
      })
      |> Repo.insert!()

    case_following =
      %Case{}
      |> Case.changeset(%{
        case_number: "CR01-16-00003",
        county: "valid",
        type: "criminal",
        first_name: "John",
        last_name: "Doe",
        hearings: [
          %{time: ~T[09:00:00], date: Date.add(Date.utc_today(), 2)},
          %{time: ~T[09:00:00], date: Date.add(Date.utc_today(), 364)}
        ]
      })
      |> Repo.insert!()

    %Subscriber{}
    |> Subscriber.changeset(%{
      case_id: case_today.id,
      phone_number: "12025550170",
      locale: "en"
    })
    |> Repo.insert!()

    %Subscriber{}
    |> Subscriber.changeset(%{
      case_id: case_tomorrow.id,
      phone_number: "12025550170",
      locale: "en"
    })
    |> Repo.insert!()

    %Subscriber{}
    |> Subscriber.changeset(%{
      case_id: case_following.id,
      phone_number: "12025550170",
      locale: "en"
    })
    |> Repo.insert!()


    {:ok, %{}}
  end

  test "given subscribers there should be one pending notification" do
    pending_notifications = Notify.notifications_for_day(DateTime.utc_now())

    assert length(pending_notifications) === 1

    Notify.run()

    Process.sleep(500)

    assert length(from(n in Notification) |> Repo.all()) === 1
  end
end
