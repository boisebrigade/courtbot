defmodule ExCourtbotWeb.Case do
  use Ecto.Schema

  alias ExCourtbot.Repo
  alias ExCourtbotWeb.{Case, Hearing, Subscriber}

  import Ecto.{Changeset, Query}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "cases" do
    field(:case_number, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:county, :string)

    has_many(:hearings, Hearing, on_delete: :delete_all)
    has_many(:subscribers, Subscriber, on_delete: :delete_all)

    timestamps()
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> cast(params, [:case_number, :first_name, :last_name, :county])
    |> update_change(:case_number, &clean_case_number/1)
    |> update_change(:county, &clean_county/1)
    |> cast_assoc(:hearings)
    |> validate_required([:case_number])
  end

  def find_by_case_number(case_number) do
    from(
      c in Case,
      where: c.case_number == ^case_number,
      preload: :hearings
    )
    |> Repo.all()
  end

  def find(id) do
    from(
      c in Case,
      where: c.id == ^id,
      preload: :hearings
    )
    |> Repo.one()
  end

  def find_with_county(case_number, county) do
    from(
      c in Case,
      where: c.case_number == ^case_number,
      where: c.county == ^county,
      preload: :hearings
    )
    |> Repo.all()
  end

  defp clean_county(county) do
    county
    |> String.trim()
    |> String.downcase()
  end

  defp clean_case_number(case_number) do
    case_number
    |> String.trim()
    |> String.downcase()
    |> String.replace("-", "")
    |> String.replace("_", "")
    |> String.replace(",", "")
  end
end
