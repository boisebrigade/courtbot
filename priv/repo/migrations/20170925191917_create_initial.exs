defmodule ExCourtbot.Repo.Migrations.CreateInitial do
  use Ecto.Migration

  def change do
    create table(:queued, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :phone_number, :binary
      add :case_number, :string

      timestamps()
    end

    create table(:cases, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :type, :string
      add :case_number, :string
      add :first_name, :string
      add :last_name, :string
      add :county, :string

      timestamps()
    end

    create index(:cases, [:case_number], unique: true, where: "type is null and county is null")
    create index(:cases, [:case_number, :county], unique: true, where: "type is null")
    create index(:cases, [:case_number, :type], unique: true, where: "county is null")
    create unique_index(:cases, [:case_number, :county, :type])

    create table(:hearings, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :case_id, references(:cases, type: :uuid)

      add :date, :date
      add :time, :time
      add :location, :string
      add :detail, :string

      timestamps()
    end

    create table(:subscribers, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :case_id, references(:cases, type: :uuid)

      add :phone_number, :binary
      add :locale, :string

      timestamps()
    end

    create table(:notifications, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :subscriber_id, references(:subscribers, type: :uuid)
      add :hearing_id, references(:hearings, type: :uuid)

      timestamps()
    end
  end
end
