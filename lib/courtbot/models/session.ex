defmodule Courtbot.Sessions do
  use Ecto.Schema

  alias Courtbot.Case

  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "sessions" do
    field(:data, :map)
    field(:expires_at, :naive_datetime)

    timestamps()
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> cast(params, [:id, :data, :expires_at])
  end
end
