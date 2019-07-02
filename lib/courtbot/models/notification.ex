defmodule Courtbot.Notification do
  use Ecto.Schema

  alias Courtbot.{Subscriber, Configuration}

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "notifications" do
    belongs_to(:subscriber, Subscriber)

    field(:type, :string)
    field(:message, :string)
    field(:status, :string)
    field(:sid, :string)
    field(:interval, :string)


    timestamps()
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> cast(params, [:id, :subscriber_id, :type, :status, :message, :sid, :interval])
  end
end
