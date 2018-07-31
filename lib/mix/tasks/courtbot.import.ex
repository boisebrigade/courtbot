defmodule Mix.Tasks.Courtbot.Import do
  use Mix.Task

  @shortdoc "Run the ExCourtbot import"
  def run(_) do
    Mix.Task.run("app.start", [])

    ExCourtbot.import()
  end
end
