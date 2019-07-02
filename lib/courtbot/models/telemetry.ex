defmodule Courtbot.Telemetry do
  use Ecto.Schema

  alias Courtbot.Case

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "telemetry" do
    belongs_to(:case, Case)

    field(:category, :string)
    field(:subcategory, :string)
    field(:event, :string)
    field(:measurement, :string)
    field(:metadata, :string)

    timestamps()
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> cast(params, [:category, :subcategory, :event])
  end
end
