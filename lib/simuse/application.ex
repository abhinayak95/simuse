defmodule Simuse.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Simuse.Repo,
      # Start the Telemetry supervisor
      SimuseWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Simuse.PubSub},
      # Start the Endpoint (http/https)
      SimuseWeb.Endpoint
      # Start a worker by calling: Simuse.Worker.start_link(arg)
      # {Simuse.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Simuse.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    SimuseWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
