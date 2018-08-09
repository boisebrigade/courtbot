defmodule ExCourtbot.Repo do
  use Ecto.Repo, otp_app: :excourtbot

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, config) do
    if config[:load_from_system_env] do
      database_url =
        System.get_env("DATABASE_URL") ||
          raise "expected the DATABASE_URL environment variable to be set"

      config =
        config
        |> Keyword.put(:url, database_url)

      {:ok, config}
    else
      {:ok, config}
    end
  end
end
