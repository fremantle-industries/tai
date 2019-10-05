defmodule Tai.VenueAdapters.Gdax.Stream.ProcessOrderBook do
  use GenServer
  alias Tai.Markets.OrderBook

  defmodule State do
    @type venue_id :: Tai.Venues.Adapter.venue_id()
    @type product_symbol :: Tai.Venues.Product.symbol()
    @type t :: %State{venue: venue_id, symbol: product_symbol}

    @enforce_keys ~w(venue symbol)a
    defstruct ~w(venue symbol)a
  end

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type product :: Tai.Venues.Product.t()
  @type venue_symbol :: Tai.Venues.Product.venue_symbol()
  @type state :: State.t()

  @spec start_link(product) :: GenServer.on_start()
  def start_link(product) do
    state = %State{venue: product.venue_id, symbol: product.symbol}
    name = to_name(product.venue_id, product.venue_symbol)

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec to_name(venue_id, venue_symbol :: String.t()) :: atom
  def to_name(venue_id, venue_symbol), do: :"#{__MODULE__}_#{venue_id}_#{venue_symbol}"

  @spec init(state) :: {:ok, state}
  def init(state), do: {:ok, state}

  def handle_cast({:snapshot, %{"bids" => bids, "asks" => asks}, received_at}, state) do
    normalized_bids = bids |> normalize_snapshot_changes(:bid)
    normalized_asks = asks |> normalize_snapshot_changes(:ask)

    %OrderBook.ChangeSet{
      venue: state.venue,
      symbol: state.symbol,
      last_received_at: received_at,
      changes: Enum.concat(normalized_bids, normalized_asks)
    }
    |> OrderBook.replace()

    {:noreply, state}
  end

  def handle_cast({:update, %{"changes" => changes, "time" => time}, received_at}, state) do
    {:ok, venue_timestamp} = Timex.parse(time, "{ISO:Extended}")
    normalized_changes = changes |> normalize_update_changes()

    %OrderBook.ChangeSet{
      venue: state.venue,
      symbol: state.symbol,
      last_venue_timestamp: venue_timestamp,
      last_received_at: received_at,
      changes: normalized_changes
    }
    |> OrderBook.apply()

    {:noreply, state}
  end

  defp normalize_snapshot_changes(data, side) do
    data
    |> Enum.map(fn [venue_price, venue_size] ->
      {price, _} = Float.parse(venue_price)
      {size, _} = Float.parse(venue_size)
      {:upsert, side, price, size}
    end)
  end

  defp normalize_update_changes(changes) do
    changes
    |> Enum.map(fn [side, venue_price, venue_size] ->
      {price, _} = Float.parse(venue_price)
      {size, _} = Float.parse(venue_size)
      {side, price, size}
    end)
    |> Enum.map(fn
      {"buy", price, 0.0} -> {:delete, :bid, price}
      {"buy", price, size} -> {:upsert, :bid, price, size}
      {"sell", price, 0.0} -> {:delete, :ask, price}
      {"sell", price, size} -> {:upsert, :ask, price, size}
    end)
  end
end
