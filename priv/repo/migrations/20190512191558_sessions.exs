defmodule Courtbot.Repo.Migrations.Sessions do
  use Ecto.Migration

  def change do
    create table(:sessions, primary_key: false) do
      add :id, :string, primary_key: true

      add :data, :map, default: %{}
      add :expires_at, :naive_datetime

      timestamps()
    end
  end
end
