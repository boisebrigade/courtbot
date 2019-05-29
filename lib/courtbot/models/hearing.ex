defmodule Courtbot.Hearing do
  use Ecto.Schema

  alias Courtbot.{Case, Configuration}

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

  def changeset(
        changeset,
        params \\ %{},
        %{importer: %{field_mapping: field_mapping}} \\ Configuration.get([:importer])
      ) do
    date_and_time = Map.take(params, [:date, :time])

    field_mapping =
      Enum.reduce(field_mapping, %{}, fn
        mapping = %{destination: destination}, acc
        when destination === "date" or destination === "time" or destination === "datetime" ->
          Map.put(acc, String.to_existing_atom(destination), mapping)

        _, acc ->
          acc
      end)

    params =
      case date_and_time do
        %{date: _, time: _} -> Map.merge(params, cast_date_and_time(date_and_time, field_mapping))
        _ -> params
      end

    changeset
    |> cast(params, [:case_id, :time, :date, :location, :detail])
    |> validate_required([:date, :time])
    |> validate_length(:location, max: 255)
    |> validate_length(:detail, max: 255)
    |> unique_constraint(:case_id, name: :hearings_case_id_date_time_index)
    |> unique_constraint(:date, name: :hearings_case_id_date_time_index)
    |> unique_constraint(:time, name: :hearings_case_id_date_time_index)
  end

  def cast_date_and_time(date_and_time = %{date: date, time: time}, %{
        date: %{format: date_format},
        time: %{format: time_format}
      })
      when is_binary(date) and is_binary(time) do
    date_and_time
    |> Map.put(:date, date |> String.trim() |> Timex.parse!(date_format, :strftime))
    |> Map.put(:time, time |> String.trim() |> Timex.parse!(time_format, :strftime))
  end

  def cast_date_and_time(date_and_time, _), do: date_and_time

  def format(hearing) do
    hearing
    |> Map.take([:date, :time, :detail, :location])
    |> Map.update!(:date, fn date ->
      Timex.format!(date, "%m/%d/%Y", :strftime)
    end)
    |> Map.update!(:time, fn time ->
      Timex.format!(time, "%I:%M %p", :strftime)
    end)
  end
end
