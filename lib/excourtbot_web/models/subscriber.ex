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
    field(:phone_number_hash, :binary)
    field(:locale, :string)

    has_many(:notifications, Notification, on_delete: :delete_all)

    timestamps()
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> cast(params, [:case_id, :phone_number, :locale])
    |> validate_length(:phone_number, min: 9)
    |> validate_required([:phone_number, :locale])
    |> hash_phone_number
    |> unique_constraint(:case_id, name: :subscribers_case_id_phone_number_hash_index)
  end

  def count_by_number(phone_number) do
    from(
      s in Subscriber,
      select: count(s.id)
    )
    |> where_phone_number(phone_number)
    |> Repo.one()
  end

  def already_subscribed?(case_id, phone_number) do
    query =
      from(
        s in Subscriber,
        where: s.case_id == ^case_id,
        select: 1
      )
      |> where_phone_number(phone_number)

    case Repo.one(query) do
      1 -> true
      _ -> false
    end
  end

  def find_by_number_and_case(case_id, phone_number) do
    from(
      s in Subscriber,
      where: s.case_id == ^case_id
    )
    |> where_phone_number(phone_number)
    |> Repo.one()
  end

  def find_by_number(phone_number) do
    from(s in Subscriber)
    |> where_phone_number(phone_number)
  end

  def all_pending_notifications() do
    today = Date.utc_today()
    tomorrow = Date.add(today, 1)

    notified =
      from(
        n in Notification,
        where: n.inserted_at >= ^Timex.beginning_of_day(DateTime.utc_now()),
        where: n.inserted_at <= ^Timex.end_of_day(DateTime.utc_now()),
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

  defp where_phone_number(query, phone_number) do
    hashed = :crypto.hash(:sha256, phone_number)

    query
    |> where([s], s.phone_number_hash == ^hashed)
  end

  defp hash_phone_number(changeset) do
    if get_change(changeset, :phone_number) do
      changeset
      |> put_change(
        :phone_number_hash,
        :crypto.hash(:sha256, get_change(changeset, :phone_number))
      )
    else
      changeset
    end
  end
end
