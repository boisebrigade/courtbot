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

    has_many(:hearings, Hearing)
    has_many(:subscribers, Subscriber)

    timestamps()
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> cast(params, [:case_number, :first_name, :last_name, :county])
    |> cast_assoc(:hearings)
    |> validate_required([:case_number])
  end

  def find(case_number) do
    from(c in Case,
      where: c.case_number == ^case_number,
      preload: :hearings)
    |> Repo.all
  end

  def find_with_county(case_number, county) do
    from(c in Case,
      where: c.case_number == ^case_number,
      where: c.county == ^county,
      preload: :hearings)
    |> Repo.all
  end
end
