defmodule Mix.Tasks.Courtbot.User.Password do
  use Mix.Task

  alias Courtbot.User

  @random_passphase_length 32

  @shortdoc "Reset's Courtbot's admin users password"
  def run(_) do
    Mix.Task.run("app.start", [])

    password = :crypto.strong_rand_bytes(@random_passphase_length) |> Base.encode64 |> binary_part(0, @random_passphase_length)

    User.reset_password("admin", password)

    IO.puts("New password: #{password}")
  end
end
