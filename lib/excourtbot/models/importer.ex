defmodule ExCourtbot.Importer do
  use Ecto.Schema

  import Ecto.{Changeset, Query}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "importer" do
    field(:from, :string)
    field(:to, :string)
    field(:type, :string)
    field(:format, :string)
    field(:order, :integer)

    timestamps()
  end
end
