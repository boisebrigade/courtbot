defmodule ExCourtbotWeb.Notification do
  use Ecto.Schema

  alias ExCourtbotWeb.{Case, Hearing}

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "notifications" do
    belongs_to(:subscriber, Subscriber)

    timestamps()
  end

  def changeset(changeset, params \\ %{}) do
    changeset
  end
end
