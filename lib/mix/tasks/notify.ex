defmodule Mix.Tasks.Notify do
  use Mix.Task

  @shortdoc "Run the ExCourtbot notify"
  def run(_) do
    Mix.Task.run("app.start", [])

    ExCourtbot.notify()
  end
end
