defmodule ExCourtbotWeb.Csv do
  alias ExCourtbot.Repo
  alias ExCourtbotWeb.Case

  def import(csv_data, headings) do
    csv_data
    |> CSV.decode(headers: headings)
    |> Enum.map(fn
        {:ok, %{date: date, time: time, case_number: case_number}} ->
          %Case{}
          |> Case.changeset(%{
            case_number: case_number,
            hearings: [
              %{
                time: time,
                date: date
              }
            ]
          })
          |> Repo.insert
        {:error, message} ->
          {:error, message}
    end)
  end

  def import(csv_data) do
    headings =  Application.get_env(:excourtbot, :csv_headings)

    # TODO(ts): Allow headings to define date formats and break time out of a date if format contains it
    headings
    |> case do
      headings when is_list(headings) -> ExCourtbot.Csv.import(csv_data, headings)
      _ -> ExCourtbot.Csv.import(csv_data, true)
    end
  end
end
