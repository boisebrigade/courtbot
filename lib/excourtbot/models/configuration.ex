defmodule ExCourtbot.Configuration do
  use Ecto.Schema

  import Ecto.{Changeset, Query}

  alias ExCourtbot.Configuration

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "configuration" do
    field(:name, :string)
    field(:value, :string)

    timestamps()
  end

  def get_conf(conf), do: from(c in Configuration, where: c.name in ^conf, select: %{c.name => c.value})
end
