defmodule Mix.Tasks.Courtbot.User.Password do
  use Mix.Task

  alias ExCourtbot.User

  @shortdoc "Reset's Courtbot's admin users password"
  def run(_) do
    Mix.Task.run("app.start", [])

    password = "abcdefghijk"

    User.reset_password("admin", password)

    IO.puts "New password: #{password}"

  end
end
