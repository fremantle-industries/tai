defmodule Tai.VenueAdapters.OkEx.Stream.OrderBookStore do
  use GenServer
  require Logger

  defmodule State do
    @type venue_id :: Tai.Venues.Adapter.venue_id()
    @type t :: %State{venue: venue_id, symbol: atom}

    @enforce_keys ~w(venue symbol)a
    defstruct ~w(venue symbol)a
  end

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type venue_symbol :: String.t()
  @type state :: State.t()

  def start_link(venue_id: venue_id, symbol: symbol, venue_symbol: venue_symbol) do
    store = %State{venue: venue_id, symbol: symbol}
    name = to_name(venue_id, venue_symbol)
    GenServer.start_link(__MODULE__, store, name: name)
  end

  @spec init(state) :: {:ok, state}
  def init(state), do: {:ok, state}

  @spec to_name(venue_id, venue_symbol) :: atom
  def to_name(venue_id, venue_symbol), do: :"#{__MODULE__}_#{venue_id}_#{venue_symbol}"

  @bids "bids"
  @asks "asks"
  def handle_cast(
        {:snapshot, %{"timestamp" => timestamp} = data, received_at},
        state
      ) do
    {:ok, venue_sent_at, _} = DateTime.from_iso8601(timestamp)
    normalized_bids = data |> normalize(@bids, received_at, venue_sent_at)
    normalized_asks = data |> normalize(@asks, received_at, venue_sent_at)

    snapshot = %Tai.Markets.OrderBook{
      venue_id: state.venue,
      product_symbol: state.symbol,
      bids: normalized_bids,
      asks: normalized_asks
    }

    :ok = Tai.Markets.OrderBook.replace(snapshot)

    {:noreply, state}
  end

  def handle_cast(
        {:update, %{"timestamp" => timestamp} = data, received_at},
        state
      ) do
    {:ok, venue_sent_at, _} = DateTime.from_iso8601(timestamp)
    normalized_bids = data |> normalize(@bids, received_at, venue_sent_at)
    normalized_asks = data |> normalize(@asks, received_at, venue_sent_at)

    snapshot = %Tai.Markets.OrderBook{
      venue_id: state.venue,
      product_symbol: state.symbol,
      bids: normalized_bids,
      asks: normalized_asks
    }

    :ok = Tai.Markets.OrderBook.update(snapshot)

    {:noreply, state}
  end

  defp normalize(data, side, received_at, venue_sent_at) do
    data
    |> Map.get(side, [])
    |> Enum.reduce(%{}, fn
      [raw_price, raw_size, _count], acc ->
        {price, ""} = Float.parse(raw_price)
        {size, ""} = Float.parse(raw_size)
        acc |> Map.put(price, {size, received_at, venue_sent_at})

      [raw_price, raw_size, _forced_liquidations, _count], acc ->
        {price, ""} = Float.parse(raw_price)
        {size, ""} = Float.parse(raw_size)
        acc |> Map.put(price, {size, received_at, venue_sent_at})
    end)
  end
end
