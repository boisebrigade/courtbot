defmodule ExCourtbotWeb.Subscriber do
  use Ecto.Schema

  alias ExCourtbot.Repo
  alias ExCourtbotWeb.{Case, Notification, Subscriber}

  import Ecto.{Changeset, Query}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "subscribers" do
    belongs_to(:case, Case)

    field(:phone_number, ExCourtbotWeb.EncryptedField)

    has_many(:notifications, Notification, on_delete: :delete_all)

    timestamps()
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> cast(params, [:case_id, :phone_number])
    |> validate_length(:phone_number, min: 9)
    |> validate_required([:phone_number])
  end

  def unsubscribe(phone_number) do
    from(
      s in Subscriber,
      where: s.phone_number == ^phone_number
    )
    |> Repo.delete()
  end

  def all_pending_notifications() do
    from(
      s in Subscriber,
      preload: :case
    )
    |> Repo.all()
  end
end
