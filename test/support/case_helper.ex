ExUnit.start()

defmodule CourtbotTest.Helper.Case do
  @moduledoc false
  use ExUnit.CaseTemplate

  alias Courtbot.Case

  using do
    quote do
      import CourtbotTest.Helper.Case.Conversation
      import CourtbotWeb.Router.Helpers
      use CourtbotWeb.ConnCase, async: true

      # The default endpoint for testing
      @endpoint CourtbotWeb.Endpoint

      defp new_conversation(), do: build_conn()
    end
  end

  def debug_case(),
    do: %Case{
      case_number: "BEEPBOOP",
      formatted_case_number: "BEEPBOOP"
    }

  defmodule Conversation do
    @moduledoc false
    alias Courtbot.{Case, Subscriber, Repo}
    alias CourtbotWeb.Response
    use Phoenix.ConnTest

    import Ecto.Query

    @endpoint CourtbotWeb.Endpoint

    defmacro for_case(case_details, do: block) do
      quote do
        unquote(
          block
          |> Macro.prewalk(&prewalk(&1, case_details))
        )
      end
    end

    def text(conn, case, message) do
      message = replace_properties(case, message)

      conn = post(conn, "/sms/en", %{"From" => "+12025550170", "Body" => message})
      assert(conn.status === 200, "Request failed with a non 200 error: #{conn.status}")

      conn
    end

    def response(conn, case, message) do
      message =
        case
        |> replace_properties(message)
        |> HtmlEntities.encode()

      assert "<?xml version=\"1.0\" encoding=\"UTF-8\"?><Response><Sms>#{message}</Sms></Response>" ===
               conn.resp_body

      conn
    end

    defp replace_properties(case_details = %Courtbot.Case{id: case_id}, original_message) do
      subscribers =
        Repo.all(from(s in Subscriber, where: s.case_id == ^case_id, preload: :case))

      case_properties =
        case_details
        |> case_properties()
        |> Map.merge(Response.custom_variables())
        |> Map.merge(Response.cases_context(%{context: %{cases: subscribers}}))

      Enum.reduce(case_properties, original_message, fn {k, v}, message ->
        key = Atom.to_string(k)

        if String.contains?(original_message, "{#{key}}") do
          assert String.trim(v) != "", "#{key} is empty but is expected in: #{original_message}"
          assert v != nil, "#{key} is null but is expected in: #{original_message}"

          String.replace(message, "{#{key}}", v)
        else
          message
        end
      end)
    end

    defp case_properties(case_details) do
      with case = %{hearings: [hearing]} <- Case.format(case_details) do
        case |> Map.delete(:hearings) |> Map.merge(hearing)
      else
        case -> case
      end
    end

    defp prewalk({type, meta, [message]}, case) when type === :text or type === :response do
      {type, meta, [case, message]}
    end

    defp prewalk(ast, _), do: ast
  end
end
