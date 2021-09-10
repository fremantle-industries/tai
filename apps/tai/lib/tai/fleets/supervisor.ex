defmodule Tai.Fleets.Supervisor do
  use Supervisor

  @spec start_link(term) :: Supervisor.on_start()
  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(_) do
    children = [
      Tai.Fleets.AdvisorConfigStore,
      Tai.Fleets.FleetConfigStore
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
