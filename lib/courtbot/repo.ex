defmodule Courtbot.Repo do
  use Ecto.Repo,
    otp_app: :courtbot,
    adapter: Ecto.Adapters.Postgres

  def init(_, config) do
    case System.get_env("DATABASE_URL") do
      nil -> {:ok, config}
      database_url -> {:ok, Keyword.put(config, :url, database_url)}
    end
  end
end
