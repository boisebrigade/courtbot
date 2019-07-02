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
    |> trim_case_name()
    |> validate_required_inclusion([:first_name, :last_name, :case_name])
    |> validate_length(:case_name, max: 255)
    |> validate_length(:first_name, max: 255)
    |> validate_length(:last_name, max: 255)
    |> unique_constraint(:case_id, name: :party_case_id_first_name_last_name_index)
    |> unique_constraint(:case_id, name: :party_case_id_case_name_index)
    |> unique_constraint(:case_name, name: :party_case_id_case_name_index)
    |> unique_constraint(:first_name, name: :party_case_id_first_name_last_name_index)
    |> unique_constraint(:last_name, name: :party_case_id_first_name_last_name_index)
  end

  def validate_required_inclusion(changeset, fields) do
    if Enum.any?(fields, &present?(changeset, &1)) do
      changeset
    else
      # Add the error to the first field only since Ecto requires a field name for each error.
      add_error(changeset, hd(fields), "One of these fields must be present: #{inspect(fields)}")
    end
  end

  def present?(changeset, field) do
    value = get_field(changeset, field)
    value && value != ""
  end

  defp trim_case_name(changeset) do
    if get_change(changeset, :case_name) do
      case_name =
        get_change(changeset, :case_name) |> String.replace("\"", "") |> String.replace("'", "")

      put_change(changeset, :case_name, case_name)
    else
      changeset
    end
  end

  def format(%Party{first_name: first_name, last_name: last_name})
      when first_name != nil and last_name != nil,
      do: "#{first_name} #{last_name}"

  def format(%Party{case_name: case_name}), do: "\"#{String.slice(case_name, 0..50)}\""
end
