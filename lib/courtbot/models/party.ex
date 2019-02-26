defmodule Courtbot.Party do
  use Ecto.Schema

  alias Courtbot.{Case, Party}

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "party" do
    belongs_to(:case, Case)

    field(:case_name, :string)
    field(:first_name, :string)
    field(:last_name, :string)

    timestamps()
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> cast(params, [:first_name, :last_name, :case_name])
    |> unique_constraint(:case_id, name: :party_case_id_first_name_last_name_index)
    |> unique_constraint(:case_id, name: :party_case_id_case_name_index)
    |> unique_constraint(:case_name, name: :party_case_id_case_name_index)
    |> unique_constraint(:first_name, name: :party_case_id_first_name_last_name_index)
    |> unique_constraint(:last_name, name: :party_case_id_first_name_last_name_index)
  end

  def format(%Party{first_name: first_name, last_name: lastname}) do
    "#{first_name} #{lastname}"
  end

  def format(%Party{case_name: case_name}), do: String.slice(case_name, 0..50)
end
