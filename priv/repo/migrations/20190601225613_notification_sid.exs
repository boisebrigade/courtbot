defmodule Courtbot.Repo.Migrations.NotificationSid do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      add :sid, :string
    end

    create index(:notifications, [:sid])
  end
end
