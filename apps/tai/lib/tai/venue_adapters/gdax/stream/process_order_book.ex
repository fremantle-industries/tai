defmodule Tai.VenueAdapters.Gdax.Stream.ProcessOrderBook do
  use GenServer

  defmodule State do
    @type venue_id :: Tai.Venues.Adapter.venue_id()
    @type product_symbol :: Tai.Venues.Product.symbol()
    @type t :: %State{venue: venue_id, symbol: product_symbol}

    @enforce_keys ~w(venue symbol)a
    defstruct ~w(venue symbol)a
  end

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type product_symbol :: Tai.Venues.Product.symbol()
  @type venue_symbol :: Tai.Venues.Product.venue_symbol()
  @type state :: State.t()

  @spec start_link(venue_id: venue_id, symbol: product_symbol, venue_symbol: venue_symbol) ::
          GenServer.on_start()
  def start_link(venue_id: venue_id, symbol: symbol, venue_symbol: venue_symbol) do
    state = %State{venue: venue_id, symbol: symbol}
    name = to_name(venue_id, venue_symbol)

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec init(state) :: {:ok, state}
  def init(state), do: {:ok, state}

  def handle_cast({:snapshot, %{"bids" => bids, "asks" => asks}, received_at}, state) do
    snapshot = %Tai.Markets.OrderBook{
      venue_id: state.venue,
      product_symbol: state.symbol,
      bids: bids |> normalize_snapshot(),
      asks: asks |> normalize_snapshot(),
      last_received_at: received_at
    }

    Tai.Markets.OrderBook.replace(snapshot)

    {:noreply, state}
  end

  def handle_cast({:update, %{"changes" => changes, "time" => time}, received_at}, state) do
    venue_timestamp = Timex.parse!(time, "{ISO:Extended}")
    normalized_changes = normalize_update(changes, received_at, venue_timestamp, state)
    Tai.Markets.OrderBook.update(normalized_changes)

    {:noreply, state}
  end

  @spec to_name(venue_id, venue_symbol :: String.t()) :: atom
  def to_name(venue_id, venue_symbol), do: :"#{__MODULE__}_#{venue_id}_#{venue_symbol}"

  defp normalize_snapshot(snapshot_side) do
    snapshot_side
    |> Enum.reduce(%{}, fn [price, size], acc ->
      {parsed_price, _} = Float.parse(price)
      {parsed_size, _} = Float.parse(size)
      Map.put(acc, parsed_price, parsed_size)
    end)
  end

  defp normalize_update(changes, received_at, venue_timestamp, state) do
    changes
    |> Enum.reduce(
      %Tai.Markets.OrderBook{
        venue_id: state.venue,
        product_symbol: state.symbol,
        bids: %{},
        asks: %{},
        last_received_at: received_at,
        last_venue_timestamp: venue_timestamp
      },
      fn [side, price, size], acc ->
        {parsed_price, _} = Float.parse(price)
        {parsed_size, _} = Float.parse(size)
        nside = side |> normalize_side

        new_price_levels =
          acc
          |> Map.get(nside)
          |> Map.put(parsed_price, parsed_size)

        acc
        |> Map.put(nside, new_price_levels)
      end
    )
  end

  defp normalize_side("buy"), do: :bids
  defp normalize_side("sell"), do: :asks
end
