defmodule Examples.Application do
  use Application

  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies, [])

    [{Cluster.Supervisor, [topologies, [name: Examples.ClusterSupervisor]]}]
    |> Supervisor.start_link(strategy: :one_for_one, name: Examples.Supervisor)
  end
end
