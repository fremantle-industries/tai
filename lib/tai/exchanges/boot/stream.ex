defmodule Tai.Exchanges.Boot.Stream do
  @type adapter :: Tai.Exchanges.Adapter.t()
  @type product :: Tai.Exchanges.Product.t()

  @spec start(adapter :: adapter, products :: [product]) :: DynamicSupervisor.on_start_child()
  def start(adapter, products) do
    Tai.Venues.StreamsSupervisor.start_stream(
      adapter.adapter.stream_supervisor,
      adapter.id,
      adapter.accounts,
      products
    )
  end
end
