defmodule ExCourtbot.Queue do
  use Ecto.Schema

  alias ExCourtbot.Case

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "queue" do
    belongs_to(:case, Case)

    field(:case_number, :string)
    field(:phone_number, ExCourtbot.Encrypted.Binary)

    timestamps()
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> cast(params, [:case_number, :phone_number])
    |> validate_required([:case_number, :phone_number])
  end
end
