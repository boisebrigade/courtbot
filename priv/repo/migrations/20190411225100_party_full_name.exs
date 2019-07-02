defmodule Courtbot.Repo.Migrations.PartyFullName do
  use Ecto.Migration

  def change do

    alter table(:party) do
      add :full_name, :string
    end

    create unique_index(:party, [:case_id, :full_name])

  end
end
