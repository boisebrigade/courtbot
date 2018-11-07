defmodule Courtbot.Case do
  use Ecto.Schema

  alias Courtbot.{Case, Hearing, Subscriber, Repo}

  import Ecto.{Changeset, Query}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "cases" do
    field(:type, :string)
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
    |> cast(params, [:type, :case_number, :first_name, :last_name, :county])
    |> update_change(:case_number, &clean_case_number/1)
    |> update_change(:county, &clean_county/1)
    |> cast_assoc(:hearings)
    |> validate_required([:case_number])
    |> unique_constraint(:case_number, name: :cases_case_number_index)
    |> unique_constraint(:case_number, name: :cases_case_number_type_index)
    |> unique_constraint(:case_number, name: :cases_case_number_county_index)
    |> unique_constraint(:case_number, name: :cases_case_number_county_type_index)
  end

  def find_by_case_number(case_number) do
    from(
      c in Case,
      where: c.case_number == ^case_number
    )
    |> latest_hearing()
    |> Repo.all()
  end

  def find(id) do
    from(
      c in Case,
      where: c.id == ^id
    )
    |> latest_hearing()
    |> Repo.one()
  end

  def find_with_county(case_number, county) do
    from(
      c in Case,
      where: c.case_number == ^case_number,
      where: c.county == ^county
    )
    |> latest_hearing()
    |> Repo.all()
  end

  def all_counties() do
    # TODO(ts): Case sensitivity?
    from(c in Case, select: c.county) |> Repo.all()
  end

  defp latest_hearing(query) do
    latest_hearing =
      from(h in Hearing, order_by: [h.date, h.time], limit: 1, where: h.date >= ^Date.utc_today())

    query
    |> preload(hearings: ^latest_hearing)
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
