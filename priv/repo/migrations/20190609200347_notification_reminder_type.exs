defmodule Courtbot.Repo.Migrations.NotificationReminderInterval do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      add :interval, :string
    end

  end
end
