defmodule Courtbot.Repo.Migrations.Telemetry do
  use Ecto.Migration

  def change do

    create table(:telemetry, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :category, :string
      add :sub_category, :string
      add :event, :string
      add :measurement, :map, default: %{}
      add :metadata, :map, default: %{}

      timestamps()
    end

  end
end
