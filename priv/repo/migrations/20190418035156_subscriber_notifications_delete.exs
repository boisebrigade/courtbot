defmodule Courtbot.Repo.Migrations.SubscriberNotificationsDelete do
  use Ecto.Migration

  def up do
    drop constraint(:notifications, "notifications_subscriber_id_fkey")
    alter table(:notifications) do
      modify :subscriber_id, references(:subscribers, type: :uuid, on_delete: :delete_all)
    end
  end
end
