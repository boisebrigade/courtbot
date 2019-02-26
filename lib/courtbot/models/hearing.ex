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

  def changeset(changeset, params \\ %{}) do
    date_and_time = Map.take(params, [:date, :time])

    params =
      case date_and_time do
        %{date: _, time: _} -> Map.merge(params, cast_date_and_time(date_and_time))
        %{} -> params
      end

    changeset
    |> cast(params, [:case_id, :time, :date, :location, :detail])
    |> validate_required([:date, :time])
    |> unique_constraint(:case_id, name: :hearings_case_id_date_time_index)
    |> unique_constraint(:date, name: :hearings_case_id_date_time_index)
    |> unique_constraint(:time, name: :hearings_case_id_date_time_index)
  end

  def cast_date_and_time(date_and_time = %{date: date, time: time})
      when is_binary(date) and is_binary(time) do
    %{format: time_format} = Configuration.importer_field_mapping("time")
    %{format: date_format} = Configuration.importer_field_mapping("date")

    date_and_time
    |> Map.put(:date, date |> String.trim() |> Timex.parse!(date_format, :strftime))
    |> Map.put(:time, time |> String.trim() |> Timex.parse!(time_format, :strftime))
  end

  def cast_date_and_time(date_and_time), do: date_and_time

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
