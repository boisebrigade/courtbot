defmodule ExCourtbotWeb.Subscriber do
  use Ecto.Schema

  alias ExCourtbotWeb.{Case, Hearing, Notification}

  import Ecto.Changeset

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
    |> validate_length(:phone_number, min: 10)
  end

  def unsubscribe(phone_number) do
  end

  def all_pending_notifications() do
    #    from(
    #      s in Subscriber,
    #      preload: :hearings
    #    )
    #    |> Repo.all()
  end
end
