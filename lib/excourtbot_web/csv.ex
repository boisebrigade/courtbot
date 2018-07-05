defmodule ExCourtbotWeb.Csv do
  alias ExCourtbot.Repo
  alias ExCourtbotWeb.Case

  require Logger

  def extract(csv_data, %{has_headings: has_headings, headings: headings, delimiter: delimiter}) do
    decoded_csv = csv_data
    |> CSV.decode(headers: headings, separator: delimiter)

    if has_headings do
      decoded_csv |> Enum.drop(1)
    else
      decoded_csv
    end
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

  def extract(csv_data, %{has_headings: has_headings, headings: headings}), do: ExCourtbotWeb.Csv.extract(csv_data, %{has_headings: has_headings, headings: headings, delimiter: ?,})
  def extract(csv_data, %{headings: headings}), do: ExCourtbotWeb.Csv.extract(csv_data, %{has_headings: true, headings: headings, delimiter: ?,})
end
