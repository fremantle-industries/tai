defmodule Tai.VenueAdapters.OkEx.Stream.ProcessOrderBook do
  use GenServer

  defmodule State do
    @type venue_id :: Tai.Venues.Adapter.venue_id()
    @type t :: %State{venue: venue_id, symbol: atom}

    @enforce_keys ~w(venue symbol)a
    defstruct ~w(venue symbol)a
  end

  @type venue_id :: Tai.Venues.Adapter.venue_id()
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

  @bids "bids"
  @asks "asks"
  def handle_cast(
        {:snapshot, %{"timestamp" => timestamp} = data, received_at},
        state
      ) do
    {:ok, venue_timestamp, _} = DateTime.from_iso8601(timestamp)

    snapshot = %Tai.Markets.OrderBook{
      venue_id: state.venue,
      product_symbol: state.symbol,
      bids: data |> normalize(@bids),
      asks: data |> normalize(@asks),
      last_received_at: received_at,
      last_venue_timestamp: venue_timestamp
    }

    :ok = Tai.Markets.OrderBook.replace(snapshot)

    {:noreply, state}
  end

  def handle_cast(
        {:update, %{"timestamp" => timestamp} = data, received_at},
        state
      ) do
    {:ok, venue_timestamp, _} = DateTime.from_iso8601(timestamp)

    snapshot = %Tai.Markets.OrderBook{
      venue_id: state.venue,
      product_symbol: state.symbol,
      bids: data |> normalize(@bids),
      asks: data |> normalize(@asks),
      last_received_at: received_at,
      last_venue_timestamp: venue_timestamp
    }

    :ok = Tai.Markets.OrderBook.update(snapshot)

    {:noreply, state}
  end

  defp normalize(data, side) do
    data
    |> Map.get(side, [])
    |> Enum.reduce(%{}, fn
      [raw_price, raw_size, _count], acc ->
        {price, ""} = Float.parse(raw_price)
        {size, ""} = Float.parse(raw_size)
        acc |> Map.put(price, size)

      [raw_price, raw_size, _forced_liquidations, _count], acc ->
        {price, ""} = Float.parse(raw_price)
        {size, ""} = Float.parse(raw_size)
        acc |> Map.put(price, size)
    end)
  end
end
