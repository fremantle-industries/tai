defmodule Tai.Venues.Boot.Stream do
  @type adapter :: Tai.Venues.Adapter.t()
  @type product :: Tai.Venues.Product.t()

  @spec start(adapter :: adapter, products :: [product]) :: DynamicSupervisor.on_start_child()
  def start(adapter, products) do
    Tai.Venues.StreamsSupervisor.start_stream(
      adapter.adapter.stream_supervisor,
      adapter.id,
      adapter.channels,
      adapter.accounts,
      products,
      adapter.opts
    )
  end
end
