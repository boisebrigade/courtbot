defmodule ExCourtbot.Configuration do
  use Ecto.Schema

  import Ecto.{Changeset, Query}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "configuration" do
    field(:name, :string)
    field(:value, :string)

    timestamps()
  end
end
