defmodule Mix.Tasks.Courtbot.Notify do
  use Mix.Task

  @shortdoc "Run the Courtbot notify"
  def run(_) do
    Mix.Task.run("app.start", [])

    Courtbot.notify()
  end
end
