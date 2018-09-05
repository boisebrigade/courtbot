defmodule ExCourtbot.Notification do
  use Ecto.Schema

  alias ExCourtbot.Subscriber

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "notifications" do
    belongs_to(:subscriber, Subscriber)

    field(:sid, :string)
    field(:body, :string)

    timestamps()
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> cast(params, [:subscriber_id])
  end
end
