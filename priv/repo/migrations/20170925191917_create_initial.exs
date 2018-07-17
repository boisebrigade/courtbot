defmodule ExCourtbot.Repo.Migrations.CreateInitial do
  use Ecto.Migration

  def change do
    create table(:cases, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :case_number, :string
      add :first_name, :string
      add :last_name, :string
      add :county, :string

      timestamps()
    end

    create unique_index(:cases, [:case_number, :county])

    create table(:hearings, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :case_id, references(:cases, type: :uuid)

      add :type, :string
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
