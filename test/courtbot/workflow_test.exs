defmodule CourtbotTest.WorkflowTest do
  use Courtbot.DataCase, asyc: true

  alias Courtbot.{Case, Repo}

  setup do
    Repo.insert!(CourtbotTest.Helper.Configuration.idaho())
    Repo.insert!(CourtbotTest.Helper.Case.debug_case())

    case_details =
      %Case{}
      |> Case.changeset(%{
        case_number: "CR01-16-00001",
        county: "valid",
        type: "criminal",
        parties: [
          %{first_name: "John", last_name: "Doe"}
        ],
        hearings: [
          %{time: ~T[09:00:00], date: Date.utc_today()}
        ]
      })
      |> Repo.insert!()

    {:ok, case_details: case_details}
  end

  alias Courtbot.Workflow

  test "workflow for debug should yield beep and then boop", _ do
    {response, _state} =
      %Courtbot.Workflow{counties: true, types: true, state: :inquery}
      |> Workflow.message(from: "+12025550170", body: "beepboop")

    assert response == :boop

    {response, _state} =
      %Courtbot.Workflow{counties: true, types: true, state: :inquery}
      |> Workflow.message(from: "+12025550170", body: "beepboop")

    assert response == :beep
  end

  test "workflow for types and county", %{case_details: case_details} = _context do
    {response, state} =
      %Courtbot.Workflow{counties: true, types: true}
      |> Workflow.message(from: "+12025550170", body: case_details.case_number)

    assert response == :county

    {response, _state} =
      state
      |> Workflow.message(from: "+12025550170", body: case_details.county)

    assert response == :subscribe
  end
end
