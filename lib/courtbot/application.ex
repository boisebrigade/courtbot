defmodule Courtbot.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Courtbot.Repo, []),
      # Start the endpoint when the application starts
      supervisor(CourtbotWeb.Endpoint, [])
    ]

    # TODO(ts): Add rollbax and ex_twilio if we have their configuration

    # Grab our scheduled times and append them to our children if they are defined.
    scheduled =
      Application.get_env(:courtbot, Courtbot, %{})
      |> Map.new()
      |> Map.take([:import_time, :notify_time])
      |> Enum.map(fn
        {:import_time, import_time} ->
          %{id: "import", start: {SchedEx, :run_every, [Courtbot, :import, [], import_time]}}

        {:notify_time, notify_time} ->
          %{id: "notify", start: {SchedEx, :run_every, [Courtbot, :notify, [], notify_time]}}
      end)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Courtbot.Supervisor]
    Supervisor.start_link(children ++ scheduled, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CourtbotWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
