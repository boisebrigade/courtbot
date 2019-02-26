defmodule Courtbot.Case do
  use Ecto.Schema

  alias Courtbot.{Case, Configuration, Hearing, Party, Subscriber, Repo}

  import Ecto.{Changeset, Query}

  import CourtbotWeb.Gettext

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "cases" do
    field(:type, :string)
    field(:case_number, :string)
    field(:formatted_case_number, :string)
    field(:county, :string)

    has_many(:parties, Party, on_delete: :delete_all)
    has_many(:hearings, Hearing, on_delete: :delete_all)
    has_many(:subscribers, Subscriber, on_delete: :delete_all)

    timestamps()
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> cast(params, [
      :type,
      :case_number,
      :formatted_case_number,
      :county
    ])
    |> validate_required([:case_number])
    |> put_change(:formatted_case_number, params[:case_number])
    |> update_change(:case_number, &clean_case_number/1)
    |> update_change(:county, &clean_county/1)
    |> add_type()
    |> cast_assoc(:hearings)
    |> cast_assoc(:parties)
    |> unique_constraint(:case_number, name: :cases_case_number_index)
    |> unique_constraint(:case_number, name: :cases_case_number_type_index)
    |> unique_constraint(:case_number, name: :cases_case_number_county_index)
    |> unique_constraint(:case_number, name: :cases_case_number_county_type_index)
  end

  def find_with(props) do
    from(
      c in Case,
      where: ^props,
      preload: :parties
    )
    |> latest_hearing()
    |> Repo.one()
  end

  def all_counties(),
    do:
      from(
        c in Case,
        distinct: true,
        select: c.county,
        where: not is_nil(c.county)
      )
      |> Repo.all()

  def format(case) do
    case
    |> Map.take([
      :case_number,
      :county,
      :formatted_case_number,
      :parties,
      :type,
      :hearings
    ])
    |> Map.update!(:hearings, fn hearings ->
      Enum.map(hearings, &(Hearing.format(&1)))
    end)
    |> Map.update!(:parties, fn parties ->
      parties
      |> Enum.map(&(Party.format(&1)))
      |> Enum.join(", and ")
    end)
  end

  def check_types(case_number) do
    %{types: types} = Configuration.get([:types])

    type_definitions =
      Enum.reduce(types, %{}, fn %_{name: name, pattern: value}, acc ->
        Map.put(acc, String.to_atom(name), value)
      end)

    Enum.reduce(type_definitions, nil, fn {type, pattern}, acc ->
      case Regex.compile(pattern, [:caseless]) do
        {:ok, regex} ->
          if Regex.match?(regex, case_number) do
            type
          else
            acc
          end

        {:error, _message} ->
          acc
      end
    end)
  end

  defp latest_hearing(query),
    do:
      preload(
        query,
        hearings:
          ^from(
            h in Hearing,
            order_by: [h.date, h.time],
            limit: 1,
            where: h.date >= ^Date.utc_today()
          )
      )

  defp add_type(changeset = %Ecto.Changeset{changes: %{type: type}}) when not is_nil(type),
    do: changeset

  defp add_type(changeset = %Ecto.Changeset{changes: %{case_number: case_number}}) do
    type =
      case check_types(case_number) do
        nil -> nil
        type -> Atom.to_string(type)
      end

    changeset
    |> put_change(:type, type)
  end

  defp clean_county(county) do
    county
    |> String.replace(gettext("county"), "")
    |> String.trim()
  end

  def clean_case_number(case_number) do
    case_number
    |> String.trim()
    |> String.replace("-", "")
    |> String.replace("_", "")
    |> String.replace(",", "")
  end
end
