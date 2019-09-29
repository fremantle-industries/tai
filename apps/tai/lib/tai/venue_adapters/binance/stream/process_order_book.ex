defmodule Tai.VenueAdapters.Binance.Stream.ProcessOrderBook do
  use GenServer
  alias Tai.Markets.OrderBook

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

  @spec to_name(venue_id, venue_symbol) :: atom
  def to_name(venue, venue_symbol), do: :"#{__MODULE__}_#{venue}_#{venue_symbol}"

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
    normalized_bids = changed_bids |> normalize_changes(:bid)
    normalized_asks = changed_asks |> normalize_changes(:ask)

    %OrderBook.ChangeSet{
      venue: state.venue,
      symbol: state.symbol,
      last_venue_timestamp: venue_timestamp,
      last_received_at: received_at,
      changes: Enum.concat(normalized_bids, normalized_asks)
    }
    |> OrderBook.apply()

    {:noreply, state}
  end

  defp normalize_changes(venue_price_points, side) do
    venue_price_points
    |> Enum.map(fn [raw_price, raw_size] ->
      {price, _} = Float.parse(raw_price)
      {size, _} = Float.parse(raw_size)
      {price, size}
    end)
    |> Enum.map(fn
      {price, 0.0} -> {:delete, side, price}
      {price, size} -> {:upsert, side, price, size}
    end)
  end
end
