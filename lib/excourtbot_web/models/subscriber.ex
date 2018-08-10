defmodule ExCourtbotWeb.Subscriber do
  use Ecto.Schema

  alias ExCourtbot.Repo
  alias ExCourtbotWeb.{Case, Hearing, Notification, Subscriber}

  import Ecto.{Changeset, Query}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "subscribers" do
    belongs_to(:case, Case)

    field(:phone_number, ExCourtbot.Encrypted.Binary)
    field(:locale, :string)

    has_many(:notifications, Notification, on_delete: :delete_all)

    timestamps()
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> cast(params, [:case_id, :phone_number, :locale])
    |> validate_length(:phone_number, min: 9)
    |> validate_required([:phone_number, :locale])
  end

  def count_by_number(phone_number) do
    from(
      s in Subscriber,
      where: s.phone_number == ^phone_number,
      select: count(s.id)
    )
    |> Repo.one()
  end

  def find_by_number(phone_number) do
    from(
      s in Subscriber,
      where: s.phone_number == ^phone_number
    )
  end

  def all_pending_notifications() do
    today = Date.utc_today()
    tomorrow = Date.add(today, 1)

    notified = from(
      n in Notification,
      where: n.inserted_at >= ^Timex.beginning_of_day(DateTime.utc_now),
      where: n.inserted_at <= ^Timex.end_of_day(DateTime.utc_now),
      select: n.subscriber_id
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
      where: h.date == ^tomorrow,
      select: %{
        "subscriber_id" => s.id,
        "case_number" => c.case_number,
        "phone_number" => s.phone_number,
        "locale" => s.locale,
        "date" => h.date,
        "time" => h.time
      }
    )
    |> Repo.all()
  end
end
