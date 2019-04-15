defmodule Courtbot.Repo.Migrations.NotificationTypesResponse do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      add :type, :string
      add :message, :string
    end
  end
end
