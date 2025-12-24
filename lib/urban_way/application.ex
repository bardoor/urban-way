defmodule UrbanWay.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      UrbanWayWeb.Telemetry,
      {Bolt.Sips, Application.get_env(:bolt_sips, Bolt)},
      {DNSCluster, query: Application.get_env(:urban_way, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: UrbanWay.PubSub},
      UrbanWayWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: UrbanWay.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    UrbanWayWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
