defmodule Tai.VenueAdapters.Huobi.Stream.RouteOrderBooks do
  use GenServer
  alias Tai.VenueAdapters.Huobi.Stream

  defmodule State do
    @type venue_id :: Tai.Venue.id()
    @type venue_symbol :: Tai.Venues.Product.symbol()
    @type store_name :: atom
    @type stores :: %{optional(venue_symbol) => store_name}
    @type t :: %State{venue: venue_id, stores: stores}

    @enforce_keys ~w(venue stores)a
    defstruct ~w(venue stores)a
  end

  @type venue_id :: Tai.Venue.id()
  @type product :: Tai.Venues.Product.t()
  @type state :: State.t()

  @spec start_link(venue: venue_id, products: [product]) :: GenServer.on_start()
  def start_link(venue: venue, products: products) do
    stores = products |> build_stores()
    state = %State{venue: venue, stores: stores}
    name = venue |> to_name()
    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  @spec init(state) :: {:ok, state}
  def init(state) do
    {:ok, state}
  end

  def handle_cast(
        {
          %{"ch" => "market." <> channel, "tick" => %{"event" => "snapshot"} = tick},
          received_at
        },
        state
      ) do
    {state, channel_symbol(channel)}
    |> forward({:snapshot, tick, received_at})

    {:noreply, state}
  end

  def handle_cast(
        {
          %{"ch" => "market." <> channel, "tick" => %{"event" => "update"} = tick},
          received_at
        },
        state
      ) do
    {state, channel_symbol(channel)}
    |> forward({:update, tick, received_at})

    {:noreply, state}
  end

  defp build_stores(products) do
    products
    |> Enum.reduce(
      %{},
      fn p, acc ->
        {:ok, channel_symbol} = Stream.Channels.channel_symbol(p)
        name = Stream.ProcessOrderBook.to_name(p.venue_id, p.venue_symbol)
        Map.put(acc, channel_symbol, name)
      end
    )
  end

  defp channel_symbol(channel) do
    channel
    |> String.split(".")
    |> List.first()
  end

  defp forward({state, channel_symbol}, msg) do
    state.stores
    |> Map.fetch!(channel_symbol)
    |> GenServer.cast(msg)
  end
end
