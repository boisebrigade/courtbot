defmodule ExCourtbot.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(ExCourtbot.Repo, []),
      # Start the endpoint when the application starts
      supervisor(ExCourtbotWeb.Endpoint, [])
    ]

    # Grab our scheduled times and append them to our children if they are defined.
    scheduled =
      Application.get_env(:excourtbot, ExCourtbot, %{})
      |> Map.new()
      |> Map.take([:import_time, :notify_time])
      |> Enum.map(fn
        {:import_time, import_time} ->
          %{id: "import", start: {SchedEx, :run_every, [ExCourtbot, :import, [], import_time]}}

        {:notify_time, notify_time} ->
          %{id: "notify", start: {SchedEx, :run_every, [ExCourtbot, :notify, [], notify_time]}}
      end)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExCourtbot.Supervisor]
    Supervisor.start_link(children ++ scheduled, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ExCourtbotWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
