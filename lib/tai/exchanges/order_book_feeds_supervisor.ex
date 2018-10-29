defmodule Tai.Exchanges.OrderBookFeedsSupervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_feed(adapter, trading_products) do
    spec = {
      Tai.Exchanges.OrderBookFeedSupervisor,
      [adapter: adapter, trading_products: trading_products]
    }

    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
