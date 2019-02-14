ExUnit.start()

defmodule CourtbotWeb.CaseHelper do
  use ExUnit.CaseTemplate

  using do
    quote do
      import CourtbotWeb.CaseHelper.Helpers
      import CourtbotWeb.Router.Helpers
      use CourtbotWeb.ConnCase, async: true

      # The default endpoint for testing
      @endpoint CourtbotWeb.Endpoint

      defp new_conversation(), do: build_conn()
    end
  end

  defmodule Helpers do
    alias Courtbot.{Case, Configuration}
    use Phoenix.ConnTest

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

      conn = post(conn, "/sms/en", %{"From" => "12025550170", "Body" => message})
      assert(conn.status === 200, "Request failed with a non 200 error: #{conn.status}")

      conn
    end

    def response(conn, case, message) do
      message =
        replace_properties(case, message)
        |> HtmlEntities.encode()

      assert "<?xml version=\"1.0\" encoding=\"UTF-8\"?><Response><Sms>#{message}</Sms></Response>" ===
               conn.resp_body

      conn
    end

    def custom_variables() do
      %{variables: variables} = Configuration.get([:variables])

      Enum.reduce(variables, %{}, fn %_{name: name, value: value}, acc -> Map.put(acc, String.to_atom(name), value) end)
    end

    defp replace_properties(case_details, message) do
      case_properties = Map.merge(case_properties(case_details), custom_variables())

      Enum.reduce(case_properties, message, fn {k, v}, message ->
        key = Atom.to_string(k)

        if v do
          String.replace(message, "{#{key}}", v)
        else
          String.replace(message, "{#{key}}", "")
        end
      end)
    end

    defp case_properties(case_details) do
      case = %{hearings: [hearing]} = Case.format(case_details)
      case |> Map.delete(:hearings) |> Map.merge(hearing)
    end

    defp prewalk({type, meta, [message]}, case) when type === :text or type === :response do
      {type, meta, [case, message]}
    end

    defp prewalk(ast, _), do: ast
  end
end
