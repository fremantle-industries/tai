defmodule Tai.Venues.StreamsSupervisor do
  use DynamicSupervisor

  @type venue :: Tai.Venue.t()
  @type product :: Tai.Venues.Product.t()

  def start_link(_), do: DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok), do: DynamicSupervisor.init(strategy: :one_for_one)

  @spec start_stream(venue, [product]) :: DynamicSupervisor.on_start_child()
  def start_stream(venue, products) do
    spec = {venue.adapter.stream_supervisor, [venue: venue, products: products]}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
