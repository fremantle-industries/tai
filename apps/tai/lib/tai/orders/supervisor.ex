defmodule Tai.Orders.Supervisor do
  use Supervisor

  @type config :: Tai.Config.t()

  @spec start_link(config) :: Supervisor.on_start()
  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl true
  def init(_config) do
    [
      Tai.Orders.OrderStore,
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end
end
