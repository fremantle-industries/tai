defmodule Tai.Venues.AdaptersSupervisor do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Tai.Exchanges.Config.all()
    |> Enum.map(&Supervisor.child_spec({&1.supervisor, &1}, id: &1.id))
    |> Supervisor.init(strategy: :one_for_one)
  end
end
