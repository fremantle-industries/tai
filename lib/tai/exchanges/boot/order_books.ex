defmodule Tai.Exchanges.Boot.OrderBooks do
  @type adapter :: Tai.Exchanges.Adapter.t()
  @type product :: Tai.Exchanges.Product.t()

  @spec start(adapter :: adapter, products :: [product]) :: :ok
  def start(adapter, products) do
    # TODO: This should have much better error handling
    Tai.Exchanges.OrderBookFeedsSupervisor.start_feed(adapter, products)
    :ok
  end
end
