defmodule ExCourtbotWeb.Hearing do
  use Ecto.Schema

  alias ExCourtbot.Repo
  alias ExCourtbotWeb.{Case, Hearing}

  import Ecto.{Changeset, Query}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "hearings" do
    belongs_to(:case, Case)

    field(:type, :string)
    field(:date, :string)
    field(:time, :string)
    field(:location, :string)
    field(:detail, :string)

    timestamps()
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> cast(params, [:case_id, :type, :date, :time, :location, :detail])
    |> validate_required([:date, :time])
  end

  defp clean_time(time) do

  end

  defp clean_date() do

  end
end
