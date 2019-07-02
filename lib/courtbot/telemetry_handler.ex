defmodule Courtbot.TelemetryHandler do
  @moduledoc """
  Courtbot telemetry handler.

  Used for capturing events in an anonymous way.
  """

  alias Courtbot.{Repo, Telemetry}

  require Logger

  @doc """
  Track and log :workflow events.
  """
  def handle_event([:workflow, state, response], measurements, metadata, _config) do
    %Telemetry{}
    |> Telemetry.changeset(%{
      category: :workflow,
      subcategory: state,
      event: response,
      measurement: measurements,
      metadata: metadata
    })
    |> Repo.insert()

    Logger.debug("[workflow] #{state} #{response}")
  end
end
