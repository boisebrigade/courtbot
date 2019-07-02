defmodule Courtbot.Repo.Migrations.NotificationMessage do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      modify :message, :text
      add :status, :string
    end
  end
end
