defmodule Tai.Exchanges.Supervisor do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(
      __MODULE__,
      :ok,
      name: __MODULE__
    )
  end

  def init(:ok) do
    [
      Tai.Exchanges.Products,
      Tai.Exchanges.AdaptersSupervisor,
      # TODO
      # OrderBookFeedsSupervisor will become the responsibility of each 
      # individual adapter supervisor. Once complete it can be removed.
      Tai.Exchanges.OrderBookFeedsSupervisor
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end
end
