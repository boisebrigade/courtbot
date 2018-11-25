defmodule Courtbot.Resolver.Dashboard do
  def get(_, _, %{context: %{current_user: _user}}) do
    {:ok,
     %{
       twilio: false,
       rollbar: false,
       locales: false,
       importer: false
     }}
  end

  def get(_, _, _) do
    {:error, "Requires authentication"}
  end
end
