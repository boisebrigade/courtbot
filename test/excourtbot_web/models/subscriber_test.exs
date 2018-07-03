defmodule ExCourtbotWeb.SubscriberTest do
  use ExCourtbotWeb.ConnCase, async: true

  alias Ecto.Multi
  alias ExCourtbot.Repo
  alias ExCourtbotWeb.{Case, Hearing, Subscriber}

  @case_id Ecto.UUID.generate
  @hearing_id Ecto.UUID.generate
  @subscriber_id Ecto.UUID.generate

  setup do
    Multi.new
    |>Multi.insert(:case, %Subscriber{
      id: @case_id,
    })
    |>Multi.insert(:hearing, %Hearing{
      id: @hearing_id,
    })
    |>Multi.insert(:subscriber, %Subscriber{
      id: @subscriber_id,
    })
    |> Repo.transaction

    :ok
  end

  # test "" do
  #   Repo.get(Subscriber, @subscriber_id) |> IO.inspect
  # end
end
