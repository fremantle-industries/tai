defmodule Tai.Venues.StreamsSupervisor do
  use DynamicSupervisor

  @type adapter :: Tai.Venues.Adapter.t()
  @type product :: Tai.Venues.Product.t()

  def start_link(_), do: DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok), do: DynamicSupervisor.init(strategy: :one_for_one)

  @spec start_stream(adapter, [product]) :: DynamicSupervisor.on_start_child()
  def start_stream(venue_adapter, products) do
    spec =
      {venue_adapter.adapter.stream_supervisor,
       [venue_adapter: venue_adapter, products: products]}

    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
