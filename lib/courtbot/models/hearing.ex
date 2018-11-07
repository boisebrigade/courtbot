defmodule Courtbot.Hearing do
  use Ecto.Schema

  alias Courtbot.Case

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "hearings" do
    belongs_to(:case, Case)

    field(:date, :date)
    field(:time, :time)
    field(:location, :string)
    field(:detail, :string)

    timestamps()
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> cast(params, [:case_id, :date, :time, :location, :detail])
    |> validate_required([:date, :time])
  end
end
