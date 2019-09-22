defmodule Tai.VenueAdapters.Binance.Stream.ProcessOrderBook do
  use GenServer

  defmodule State do
    @type venue_id :: Tai.Venues.Adapter.venue_id()
    @type product_symbol :: Tai.Venues.Product.symbol()
    @type t :: %State{
            venue: venue_id,
            symbol: product_symbol
          }

    @enforce_keys ~w(venue symbol)a
    defstruct ~w(venue symbol)a
  end

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type product :: Tai.Venues.Product.symbol()
  @type venue_symbol :: Tai.Venues.Product.venue_symbol()
  @type state :: State.t()

  @spec start_link(product) :: GenServer.on_start()
  def start_link(product) do
    name = to_name(product.venue_id, product.venue_symbol)
    state = %State{venue: product.venue_id, symbol: product.symbol}

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec init(state) :: {:ok, state}
  def init(state), do: {:ok, state}

  def handle_cast(
        {
          :update,
          %{
            "E" => event_time,
            "b" => changed_bids,
            "a" => changed_asks
          },
          received_at
        },
        state
      ) do
    {:ok, venue_timestamp} = DateTime.from_unix(event_time, :millisecond)
    bids = changed_bids |> normalize(received_at, venue_timestamp)
    asks = changed_asks |> normalize(received_at, venue_timestamp)

    %Tai.Markets.OrderBook{
      venue_id: state.venue,
      product_symbol: state.symbol,
      bids: bids,
      asks: asks,
      last_received_at: received_at,
      last_venue_timestamp: venue_timestamp
    }
    |> Tai.Markets.OrderBook.update()

    {:noreply, state}
  end

  @spec to_name(venue_id, venue_symbol) :: atom
  def to_name(venue, venue_symbol), do: :"#{__MODULE__}_#{venue}_#{venue_symbol}"

  defp normalize(raw_price_levels, _received_at, _venue_sent_at) do
    raw_price_levels
    |> Enum.reduce(
      %{},
      fn [raw_price, raw_size], acc ->
        {price, _} = Float.parse(raw_price)
        {size, _} = Float.parse(raw_size)
        Map.put(acc, price, size)
      end
    )
  end
end
