defmodule Courtbot.Repo.Migrations.ConfigEmbeddedSchema do
  use Ecto.Migration

  def change do
    alter table(:configuration) do
      remove :name
      remove :value

      add :importer, :map, default: %{}
      add :rollbar, :map, default: %{}
      add :twilio, :map, default: %{}
      add :scheduled, :map, default: %{}
      add :notifications, :map, default: %{}
      add :locales, :map, default: %{}
      add :variables, {:array, :map}, default: []
      add :types, {:array, :map}, default: []
    end

    drop table(:importer)
  end
end
