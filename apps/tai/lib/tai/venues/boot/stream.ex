defmodule Tai.Venues.Boot.Stream do
  alias Tai.Venues.StreamsSupervisor

  @type adapter :: Tai.Venues.Adapter.t()
  @type product :: Tai.Venues.Product.t()

  @spec start(adapter, [product]) :: DynamicSupervisor.on_start_child()
  def start(adapter, products), do: adapter |> StreamsSupervisor.start_stream(products)
end
