defmodule ExCourtbotWeb.Notification do
  use Ecto.Schema

  alias ExCourtbotWeb.Subscriber

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "notifications" do
    belongs_to(:subscriber, Subscriber)

    timestamps()
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> cast(params, [:subscriber_id])
  end
end
