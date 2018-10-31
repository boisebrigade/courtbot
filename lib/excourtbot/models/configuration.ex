defmodule ExCourtbot.Configuration do
  use Ecto.Schema

  import Ecto.{Changeset, Query}

  alias ExCourtbot.{Repo, Configuration}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "configuration" do
    field(:name, :string)
    field(:value, :string)

    timestamps()
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> cast(params, [:name, :value])
    |> unique_constraint(:name)
  end

  def get(conf) do
    defaults =
      Enum.reduce(conf, %{}, fn key, acc ->
        Map.merge(%{String.to_atom(key) => ""}, acc)
      end)

    config =
      from(c in Configuration, where: c.name in ^conf, select: %{c.name => c.value})
      |> Repo.all()

    case config do
      [_ | _] ->
        Map.merge(
          defaults,
          config
          |> Enum.reduce(fn v, acc -> Map.merge(v, acc) end)
          |> Enum.map(fn {k, v} -> {String.to_existing_atom(k), v} end)
          |> Enum.into(%{})
        )

      [] ->
        defaults
    end
  end
end
