defmodule ExCourtbot.Repo.Migrations.DatabaseConfig do
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

      add :from, :string
      add :to, :string
      add :type, :string
      add :format, :string
      add :order, :integer

      timestamps()
    end

    create unique_index(:importer, [:order])

    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :user_name, :string
      add :password_hash, :string

      timestamps()
    end

    create unique_index(:users, [:user_name])

  end
end
