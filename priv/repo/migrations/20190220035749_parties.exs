defmodule Courtbot.Repo.Migrations.Parties do
  use Ecto.Migration

  def change do
    alter table(:cases) do
      remove :first_name
      remove :last_name
    end

    create table(:party, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :case_id, references(:cases, type: :uuid)

      add :case_name, :string
      add :first_name, :string
      add :last_name, :string

      timestamps()
    end

    create unique_index(:party, [:case_id, :first_name, :last_name])
    create unique_index(:party, [:case_id, :case_name])
    create unique_index(:hearings, [:case_id, :date, :time])

    drop table(:queued)

    alter table(:subscribers) do
      add :queued, :boolean, default: false
    end
  end
end
