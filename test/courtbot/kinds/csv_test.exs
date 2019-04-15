defmodule CourtbotTest.Kinds.CsvTest do
  use Courtbot.DataCase, asyc: false
  use ExUnitProperties

  alias Courtbot.{Repo, Kinds.Csv, Case, Hearing, Party, Configuration}
  alias CourtbotTest.GenHelper

  @idaho_headers "CaseNumber,CaseStyle,HearingType,HearingDate,HearingTime,Court,County"

  setup do
    inputs = %{
      idaho: %{
        headers: ~s"""
        #{@idaho_headers}
        """,
        single: ~s"""
        #{@idaho_headers}
        CR-2006-0011,State of Idaho vs. Warren Peace,Pre Trial,3/1/2019,9:00 AM,Canyon County Magistrate Court,Canyon
        """,
        muliple_parties: ~s"""
        #{@idaho_headers}
        CV07-18-00015,"Anna Fender, Candy Kane vs. Candy Barr, Ted E Bear",Status Conference,8/25/2019,1:00 PM,Bannock County District Court,Bannock
        CV07-18-00015,"Anna Fender, Candy Kane vs. Candy Barr, Ted E Bear",Status Conference,8/25/2019,1:00 PM,Bannock County District Court,Bannock
        CV07-18-00015,"Anna Fender, Candy Kane vs. Candy Barr, Ted E Bear",Status Conference,8/25/2019,1:00 PM,Bannock County District Court,Bannock
        CV07-18-00015,"Anna Fender, Candy Kane vs. Candy Barr, Ted E Bear",Status Conference,8/25/2019,1:00 PM,Bannock County District Court,Bannock
        CV07-18-00015,"Anna Fender, Candy Kane vs. Candy Barr, Ted E Bear",Status Conference,8/25/2019,1:00 PM,Bannock County District Court,Bannock
        CV07-18-00015,"Anna Fender, Candy Kane vs. Candy Barr, Ted E Bear",Status Conference,8/25/2019,1:00 PM,Bannock County District Court,Bannock
        """,
        multiple_hearings: ~s"""
        #{@idaho_headers}
        CR14-18-00006,State of Idaho  vs. Nick O Time,Jury Trial,4/29/2019,1:30 PM,Twin Falls County District Court,Twin Falls
        CR14-18-00006,State of Idaho  vs. Nick O Time,Status Conference,4/8/2019,2:30 PM,Twin Falls County District Court,Twin Falls
        """,
        missing_party: ~s"""
        #{@idaho_headers}
        2018-CR-00001,,Name Change Hearing,4/2/2019,1:30 PM,Ada County Magistrate Court,Ada
        """
      }
    }

    {:ok, inputs}
  end

  def to_stream(string) do
    {:ok, data} = StringIO.open(string)

    IO.binstream(data, :line)
  end

  @tag :skip
  property "importer with agreeable data can import case data" do
    Repo.insert(CourtbotTest.Helper.Configuration.idaho())

    check all case_number <- GenHelper.case_number(),
              case_style <- GenHelper.case_style(),
              hearing_type <- GenHelper.hearing_type(),
              date <- GenHelper.date("%-m/%e/%Y"),
              time <- GenHelper.time("%-I:%M %p"),
              hearing_location <- GenHelper.hearing_location(),
              county <- GenHelper.county() do
      configuration = Configuration.get([:importer, :types])

      data = ~s"""
      #{@idaho_headers}
      #{case_number},#{case_style},#{hearing_type},#{date},#{time},#{hearing_location},#{county}
      """

      {_state, _} =
        data
        |> to_stream()
        |> Csv.run(configuration)
    end
  end

  test "multiple parties", %{idaho: %{muliple_parties: data}} do
    Repo.insert(CourtbotTest.Helper.Configuration.idaho())

    configuration = Configuration.get([:importer, :types])

    Csv.run(to_stream(data), configuration)

    assert length(Repo.all(from(c in Case))) === 1
    assert length(Repo.all(from(h in Hearing))) === 1
    assert length(Repo.all(from(p in Party))) === 1

    # Reimport and check no records get duplicated
    Csv.run(to_stream(data), configuration)

    assert length(Repo.all(from(c in Case))) === 1
    assert length(Repo.all(from(h in Hearing))) === 1
    assert length(Repo.all(from(p in Party))) === 1
  end

  test "multiple hearings", %{idaho: %{multiple_hearings: data}} do
    Repo.insert(CourtbotTest.Helper.Configuration.idaho())

    configuration = Configuration.get([:importer, :types])

    Csv.run(to_stream(data), configuration)

    assert length(Repo.all(from(c in Case))) === 1
    assert length(Repo.all(from(h in Hearing))) === 2
    assert length(Repo.all(from(p in Party))) === 1

    # Reimport and check
    Csv.run(to_stream(data), configuration)

    assert length(Repo.all(from(c in Case))) === 1
    assert length(Repo.all(from(h in Hearing))) === 2
    assert length(Repo.all(from(p in Party))) === 1
  end

  test "missing party details", %{idaho: %{missing_party: data}} do
    Repo.insert(CourtbotTest.Helper.Configuration.idaho())

    configuration = Configuration.get([:importer, :types])

    Csv.run(to_stream(data), configuration)

    assert length(Repo.all(from(c in Case))) === 0
    assert length(Repo.all(from(h in Hearing))) === 0
    assert length(Repo.all(from(p in Party))) === 0
  end
end
