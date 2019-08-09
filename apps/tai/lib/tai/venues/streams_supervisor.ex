defmodule Tai.Venues.StreamsSupervisor do
  use DynamicSupervisor

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type channel :: Tai.Venues.Adapter.channel()
  @type product :: Tai.Venues.Product.t()
  @type null_supervisor :: Tai.Venues.NullStreamSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec start_stream(
          stream_supervisor :: module | null_supervisor,
          venue_id :: venue_id,
          channels :: [channel],
          accounts :: map,
          products :: [product],
          opts :: map
        ) :: DynamicSupervisor.on_start_child()
  def start_stream(Tai.Venues.NullStreamSupervisor, _, _, _, _), do: :ignore

  def start_stream(stream_supervisor, venue_id, channels, accounts, products, opts) do
    spec =
      {stream_supervisor,
       [
         venue_id: venue_id,
         channels: channels,
         accounts: accounts,
         products: products,
         opts: opts
       ]}

    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
