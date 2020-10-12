defmodule Websocket.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    topology = Application.get_env(:libcluster, :topologies)


    hosts = topology[:websocket][:config][:hosts]

    children = [
      {Cluster.Supervisor,
      [topology, [name: Websocket.ClusterSupervisor]]},
      {Mnesiac.Supervisor, [hosts, [name: Websocket.MnesiacSupervisor]]},
      # Start the Telemetry supervisor
      WebsocketWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Websocket.PubSub},
      WebsocketWeb.Presence,
      # Start the Endpoint (http/https)
      WebsocketWeb.Endpoint
      # Start a worker by calling: Websocket.Worker.start_link(arg)
      # {Websocket.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Websocket.Supervisor]
    Supervisor.start_link(children, opts)

  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    WebsocketWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp prepare_mnesia do
    master_node = config(:master_node)
    IO.inspect(master_node, label: "master_node")

    if master_node == Node.self() do
      Websocket.Mnesia.init_master()
    else
      String.to_atom(master_node)
      |> Websocket.Mnesia.add_self_to_cluster()
    end
  end

      defp config(atom) do
        Application.fetch_env!(:websocket, :controller)[atom]
      end
end
