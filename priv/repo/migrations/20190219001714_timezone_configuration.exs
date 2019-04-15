defmodule Courtbot.Repo.Migrations.TimezoneConfiguration do
  use Ecto.Migration

  def change do
    alter table(:configuration) do
      add :timezone, :string
    end
  end
end
