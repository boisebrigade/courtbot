defmodule Mix.Tasks.Courtbot.Import do
  use Mix.Task

  @shortdoc "Run the Courtbot import"
  def run(_) do
    Mix.Task.run("app.start", [])

    Courtbot.import()
  end
end
