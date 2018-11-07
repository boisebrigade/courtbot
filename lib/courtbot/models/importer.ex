defmodule Courtbot.Importer do
  use Ecto.Schema

  alias Courtbot.{Importer, Repo}
  import Ecto.{Changeset, Query}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "importer" do
    field(:index, :integer)
    field(:pointer, :string)
    field(:destination, :string)
    field(:kind, :string, default: "string")
    field(:format, :string)

    timestamps()
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> cast(params, [:index, :pointer, :destination, :kind, :format])
    |> unique_constraint(:destination)
  end

  def mapped() do
    from(i in Importer)
    |> Repo.all()
  end
end
