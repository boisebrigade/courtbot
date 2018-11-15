defmodule Courtbot.Repo.Migrations.DatabaseConfig do
  use Ecto.Migration

  def change do

    create table(:configuration, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :name, :string
      add :value, :string

      timestamps()
    end

    create unique_index(:configuration, [:name])

    create table(:importer, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :index, :integer
      add :pointer, :integer
      add :destination, :string
      add :kind, :string
      add :format, :string

      timestamps()
    end

    create unique_index(:importer, [:index])
    create unique_index(:importer, [:destination])
  end
end
