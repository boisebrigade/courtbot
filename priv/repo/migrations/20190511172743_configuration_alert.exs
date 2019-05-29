defmodule Courtbot.Repo.Migrations.ConfigurationAlert do
  use Ecto.Migration

  def change do
    alter table(:configuration) do
      add :hostname, :string
      add :usage_alerts, {:array, :map}, default: []
    end
  end
end
