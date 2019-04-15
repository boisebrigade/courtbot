defmodule Mix.Tasks.Courtbot.Notify do
  @moduledoc false
  use Mix.Task

  @shortdoc "Run the Courtbot notify"
  def run(_) do
    Mix.Task.run("app.start", [])

    Courtbot.Notify.run()
  end
end
