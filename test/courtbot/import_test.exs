defmodule CourtbotTest.ImportTest do
  use Courtbot.DataCase, asyc: true

  def count_fails(records) do
    records
    |> Enum.count(fn
      {:ok, _} -> false
      _ -> true
    end)
  end

  @tag :skip
  test "imports Anchorage data from mix config" do
    Repo.insert(CourtbotTest.Helper.Configuration.anchorage())

    records = Courtbot.Import.run()

    assert count_fails(records) == 0, "Failed to import #{count_fails(records)} records"
  end

  @tag :skip
  test "imports Atlanta data from mix config" do
    Repo.insert(CourtbotTest.Helper.Configuration.atlanta())

    records = Courtbot.Import.run()

    assert count_fails(records) == 0, "Failed to import #{count_fails(records)} records"
  end

  test "imports Idaho data from mix config" do
    Repo.insert(CourtbotTest.Helper.Configuration.idaho())

    records = Courtbot.Import.run()

    assert count_fails(records) == 2, "Failed to import #{count_fails(records)} records"
  end

  # TODO(ts): Property test input data
  # TODO(ts): Verify data is inserted correctly based upon the configured input
  # TODO(ts): Test that types and county apply
  # TODO(ts): Add tests for url sources
  # TODO(ts): Add tests for reoccurring imports
  # TODO(ts): Add tests for DB configuration
end
