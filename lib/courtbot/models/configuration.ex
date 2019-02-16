defmodule Courtbot.Configuration do
  use Ecto.Schema

  import Ecto.{Changeset, Query}
  alias Courtbot.{Repo, Configuration}

  @primary_key false
  schema "configuration" do
    embeds_one :importer, Importer, primary_key: false do
      field(:kind, :string)
      field(:origin, :string)
      field(:source, :string)
      field(:delimiter, :string, default: ",")
      field(:has_headers, :boolean, default: false)
      field(:county_duplicates, :boolean, default: false)

      embeds_many :field_mapping, FieldMapping, primary_key: false do
        field(:pointer, :string)
        field(:destination, :string)
        field(:kind, :string, default: "string")
        field(:format, :string)
      end
    end

    embeds_one :rollbar, Rollbar, primary_key: false do
      field(:access_token, :string)
      field(:environment, :string, default: "development")
    end

    embeds_one :twilio, Twilio, primary_key: false do
      field(:account_sid, :string)
      field(:auth_token, :string)
    end

    embeds_one :scheduled, Scheduled, primary_key: false do
      embeds_many :tasks, Tasks, primary_key: false do
        field(:name, :string)
        field(:crontab, :string)
      end
    end

    field(:locales, :map)

    embeds_many :variables, Variables, primary_key: false do
      field(:name, :string)
      field(:value, :string)
    end

    embeds_many :types, Types, primary_key: false do
      field(:name, :string)
      field(:pattern, :string)
    end

    embeds_one :notifications, Notifications, primary_key: false do
      field(:queuing, :boolean, default: false)
      field(:reminders, {:array, :map})
    end

    timestamps()
  end

  def importer_changeset(params) do
    %Configuration.Importer{}
    |> cast(params, [:kind, :origin, :source, :delimiter])
    |> cast_embed(:field_mapping, with: &field_mapping_changeset/1)
  end

  defp field_mapping_changeset(params) do
    %Configuration.Importer.FieldMapping{}
    |> cast(params, [:pointer, :destination, :kind, :format])
    |> unique_constraint(:destination)
  end

  defp rollbar_changeset(params) do
    %Configuration.Rollbar{}
    |> cast(params, [:access_token, :environment])
  end

  defp twilio_changeset(params) do
    %Configuration.Twilio{}
    |> cast(params, [:account_sid, :auth_token])
  end

  defp scheduled_changeset(params) do
    %Configuration.Scheduled{}
    |> cast(params, [])
    |> cast_embed(:tasks, with: &tasks_changeset/1)
  end

  defp tasks_changeset(params) do
    %Configuration.Scheduled.Tasks{}
    |> cast(params, [:import, :notify])
  end

  defp variables_changeset(params) do
    %Configuration.Variables{}
    |> cast(params, [:name, :value])
  end

  defp types_changeset(params) do
    %Configuration.Types{}
    |> cast(params, [:name, :pattern])
  end

  defp notifications_changeset(params) do
    %Configuration.Notifications{}
    |> cast(params, [:queuing, :reminders])
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> cast(params, [])
    |> cast_embed(:importer, with: &importer_changeset/1)
    |> cast_embed(:rollbar, with: &rollbar_changeset/1)
    |> cast_embed(:twilio, with: &twilio_changeset/1)
    |> cast_embed(:scheduled, with: &scheduled_changeset/1)
    |> cast_embed(:variables, with: &variables_changeset/1)
    |> cast_embed(:types, with: &types_changeset/1)
    |> cast_embed(:notifications, with: &notifications_changeset/1)
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
