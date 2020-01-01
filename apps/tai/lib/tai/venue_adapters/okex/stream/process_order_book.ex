defmodule Tai.VenueAdapters.OkEx.Stream.ProcessOrderBook do
  use GenServer
  alias Tai.Markets.OrderBook

  defmodule State do
    @type venue_id :: Tai.Venue.id()
    @type t :: %State{venue: venue_id, symbol: atom}

    @enforce_keys ~w(venue symbol)a
    defstruct ~w(venue symbol)a
  end

  @type venue_id :: Tai.Venue.id()
  @type venue_symbol :: Tai.Venues.Product.venue_symbol()
  @type product :: Tai.Venues.Product.t()
  @type state :: State.t()

  @spec start_link(product) :: GenServer.on_start()
  def start_link(product) do
    state = %State{venue: product.venue_id, symbol: product.symbol}
    name = to_name(product.venue_id, product.venue_symbol)

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec to_name(venue_id, venue_symbol) :: atom
  def to_name(venue_id, venue_symbol), do: :"#{__MODULE__}_#{venue_id}_#{venue_symbol}"

  @spec init(state) :: {:ok, state}
  def init(state), do: {:ok, state}

  def handle_cast({:snapshot, data, received_at}, state) do
    {data, received_at, state}
    |> build_change_set()
    |> OrderBook.replace()

    {:noreply, state}
  end

  def handle_cast({:update, data, received_at}, state) do
    {data, received_at, state}
    |> build_change_set()
    |> OrderBook.apply()

    {:noreply, state}
  end

  @timestamp "timestamp"
  defp build_change_set({data, received_at, state}) do
    {:ok, venue_timestamp, _} = data |> Map.fetch!(@timestamp) |> DateTime.from_iso8601()
    normalized_bids = data |> normalize_changes(:bid)
    normalized_asks = data |> normalize_changes(:ask)

    %OrderBook.ChangeSet{
      venue: state.venue,
      symbol: state.symbol,
      last_venue_timestamp: venue_timestamp,
      last_received_at: received_at,
      changes: Enum.concat(normalized_bids, normalized_asks)
    }
  end

  @bids "bids"
  @asks "asks"
  defp normalize_changes(data, :bid), do: data |> Map.get(@bids, []) |> normalize_side(:bid)
  defp normalize_changes(data, :ask), do: data |> Map.get(@asks, []) |> normalize_side(:ask)

  defp normalize_side(data, side) do
    data
    |> Enum.map(fn
      [raw_price, raw_size, _count] ->
        {price, ""} = Float.parse(raw_price)
        {size, ""} = Float.parse(raw_size)
        {price, size}

      [raw_price, raw_size, _forced_liquidations, _count] ->
        {price, ""} = Float.parse(raw_price)
        {size, ""} = Float.parse(raw_size)
        {price, size}
    end)
    |> Enum.map(fn
      {price, 0.0} -> {:delete, side, price}
      {price, size} -> {:upsert, side, price, size}
    end)
  end
end
