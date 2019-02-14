defmodule Courtbot.Subscriber do
  use Ecto.Schema

  alias Courtbot.{Case, Notification, Subscriber, Repo}

  import Ecto.{Changeset, Query}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "subscribers" do
    belongs_to(:case, Case)

    field(:phone_number, Courtbot.Encrypted.Binary)
    field(:phone_number_hash, Cloak.Fields.SHA256)
    field(:locale, :string)

    has_many(:notifications, Notification, on_delete: :delete_all)

    timestamps()
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> cast(params, [:case_id, :phone_number, :locale])
    |> validate_length(:phone_number, min: 9)
    |> validate_required([:phone_number, :locale])
    |> update_change(:phone_number, &clean_phone_number/1)
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

  def subscribers_to_case(case_id) do
    from(
      s in Subscriber,
      where: s.case_id == ^case_id
    )
    |> Repo.all()
  end

  defp where_phone_number(query, phone_number) do
    query
    |> where([s], s.phone_number_hash == ^phone_number)
  end

  defp clean_phone_number(case_number) do
    case_number
    |> String.trim()
    |> String.replace("+", "")
  end

  defp hash_phone_number(changeset) do
    if get_change(changeset, :phone_number) do
      changeset
      |> put_change(
        :phone_number_hash,
        get_change(changeset, :phone_number)
      )
    else
      changeset
    end
  end
end
