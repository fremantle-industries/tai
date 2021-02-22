defmodule Tai.VenueAdapters.Ftx.Stream.ProcessOrderBook do
  use GenServer
  alias Tai.Markets.OrderBook

  defmodule State do
    @type venue_id :: Tai.Venue.id()
    @type product_symbol :: Tai.Venues.Product.symbol()
    @type t :: %State{
            venue: venue_id,
            symbol: product_symbol,
            table: %{optional(String.t()) => number}
          }

    @enforce_keys ~w[venue symbol table]a
    defstruct ~w[venue symbol table]a
  end

  @type venue_id :: Tai.Venue.id()
  @type product :: Tai.Venues.Product.t()
  @type venue_symbol :: Tai.Venues.Product.venue_symbol()
  @type state :: State.t()

  @spec start_link(product) :: GenServer.on_start()
  def start_link(product) do
    state = %State{venue: product.venue_id, symbol: product.symbol, table: %{}}
    name = to_name(product.venue_id, product.venue_symbol)

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec to_name(venue_id, venue_symbol) :: atom
  def to_name(venue, symbol), do: :"#{__MODULE__}_#{venue}_#{symbol}"

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_cast({:snapshot, data, received_at}, state) do
    {data, received_at, state}
    |> build_change_set()
    |> OrderBook.replace()

    {:noreply, state}
  end

  @impl true
  def handle_cast({:update, data, received_at}, state) do
    {data, received_at, state}
    |> build_change_set()
    |> OrderBook.apply()

    {:noreply, state}
  end

  @timestamp "time"
  @ns_in_s 1000 * 1000 * 1000
  defp build_change_set({data, received_at, state}) do
    ns = Map.fetch!(data, @timestamp) * @ns_in_s
    {:ok, venue_timestamp} = ns |> trunc() |> DateTime.from_unix(:nanosecond)
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
    |> Enum.map(&List.to_tuple/1)
    |> Enum.map(fn
      {price, 0.0} -> {:delete, side, price}
      {price, size} -> {:upsert, side, price, size}
    end)
  end
end
