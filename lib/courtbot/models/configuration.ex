defmodule Courtbot.Configuration do
  use Ecto.Schema

  import Ecto.{Changeset, Query}
  alias Courtbot.{Repo, Configuration}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "configuration" do
    embeds_one :importer, Importer, primary_key: false, on_replace: :update do
      field(:kind, :string)
      field(:origin, :string)
      field(:source, :string)
      field(:delimiter, :string, default: ",")
      field(:has_headers, :boolean, default: false)
      field(:county_duplicates, :boolean, default: false)

      embeds_many :field_mapping, FieldMapping, primary_key: false, on_replace: :delete do
        field(:pointer, :string)
        field(:destination, :string)
        field(:kind, :string, default: "string")
        field(:format, :string)
      end
    end

    embeds_one :rollbar, Rollbar, primary_key: false, on_replace: :update do
      field(:access_token, :string)
      field(:environment, :string, default: "development")
    end

    embeds_one :twilio, Twilio, primary_key: false, on_replace: :update do
      field(:account_sid, :string)
      field(:auth_token, :string)
    end

    embeds_one :scheduled, Scheduled, primary_key: false, on_replace: :update do
      embeds_many :tasks, Tasks, primary_key: false, on_replace: :delete do
        field(:name, :string)
        field(:crontab, :string)
      end
    end

    field(:locales, :map)

    embeds_many :variables, Variables, primary_key: false, on_replace: :delete do
      field(:name, :string)
      field(:value, :string)
    end

    embeds_many :types, Types, primary_key: false, on_replace: :delete do
      field(:name, :string)
      field(:pattern, :string)
    end

    embeds_one :notifications, Notifications, primary_key: false, on_replace: :update do
      field(:queuing, :boolean, default: false)

      embeds_many :reminders, Reminders, primary_key: false, on_replace: :delete do
        field :timescale, :string
        field :offset, :integer
      end
    end

    field(:timezone, :string)

    field(:hostname, :string)

    embeds_many :usage_alerts, UsageAlerts, primary_key: false, on_replace: :delete do
      field(:amount, :integer)
      field(:recurring, :string, default: "monthly")
    end

    timestamps()
  end

  def importer_changeset(changeset, params) do
    changeset
    |> cast(params, [:kind, :origin, :source, :delimiter, :has_headers, :county_duplicates])
    |> cast_embed(:field_mapping, with: &field_mapping_changeset/2)
  end

  defp field_mapping_changeset(changeset, params) do
    changeset
    |> cast(params, [:pointer, :destination, :kind, :format])
  end

  defp rollbar_changeset(changeset, params) do
    changeset
    |> cast(params, [:access_token, :environment])
  end

  defp twilio_changeset(changeset, params) do
    changeset
    |> cast(params, [:account_sid, :auth_token])
  end

  defp scheduled_changeset(changeset, params) do
    changeset
    |> cast(params, [])
    |> cast_embed(:tasks, with: &tasks_changeset/2)
  end

  defp tasks_changeset(changeset, params) do
    changeset
    |> cast(params, [:name, :crontab])
  end

  defp variables_changeset(changeset, params) do
    changeset
    |> cast(params, [:name, :value])
  end

  defp types_changeset(changeset, params) do
    changeset
    |> cast(params, [:name, :pattern])
  end

  defp notifications_changeset(changeset, params) do
    changeset
    |> cast(params, [:queuing])
    |> cast_embed(:reminders, with: &reminders_changeset/2)
  end

  defp reminders_changeset(changeset, params) do
    changeset
    |> cast(params, [:timescale, :offset])
  end

  defp usage_alerts_changeset(changeset, params) do
    changeset
    |> cast(params, [:amount])
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> cast(params, [:timezone, :locales, :hostname])
    |> cast_embed(:importer, with: &importer_changeset/2)
    |> cast_embed(:rollbar, with: &rollbar_changeset/2)
    |> cast_embed(:twilio, with: &twilio_changeset/2)
    |> cast_embed(:scheduled, with: &scheduled_changeset/2)
    |> cast_embed(:variables, with: &variables_changeset/2)
    |> cast_embed(:types, with: &types_changeset/2)
    |> cast_embed(:notifications, with: &notifications_changeset/2)
    |> cast_embed(:usage_alerts, with: &usage_alerts_changeset/2)
  end

  def get(config) do
    Repo.one(from(c in Configuration, select: map(c, ^config)))
  end

  def mapped_county?(), do: has_field_mapped?("county")
  def mapped_type?(), do: has_field_mapped?("type")

  def importer_field_mapping(type) do
    %{importer: %{field_mapping: field_mapping}} = Configuration.get([:importer])

    case Enum.find(field_mapping, fn %{destination: destination} -> destination == type end) do
      field = %{destination: destination} when not is_nil(destination) -> field
      nil -> nil
    end
  end

  defp has_field_mapped?(type) do
    case importer_field_mapping(type) do
      %{destination: destination} when not is_nil(destination) -> true
      nil -> false
    end
  end
end
