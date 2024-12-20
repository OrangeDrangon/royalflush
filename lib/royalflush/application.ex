defmodule Royalflush.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RoyalflushWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:royalflush, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Royalflush.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Royalflush.Finch},
      # Start a worker by calling: Royalflush.Worker.start_link(arg)
      # {Royalflush.Worker, arg},
      # Start to serve requests, typically the last entry
      RoyalflushWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Royalflush.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RoyalflushWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
