defmodule Tai.VenueAdapters.Deribit.Stream.ProcessOrderBook do
  use GenServer
  alias Tai.Markets.OrderBook

  defmodule State do
    @type venue :: Tai.Venue.id()
    @type product_symbol :: Tai.Venues.Product.symbol()
    @type t :: %State{
            venue: venue,
            symbol: product_symbol
          }

    @enforce_keys ~w(venue symbol)a
    defstruct ~w(venue symbol)a
  end

  @type venue :: Tai.Venue.id()
  @type product :: Tai.Venues.Product.t()
  @type venue_symbol :: Tai.Venues.Product.venue_symbol()
  @type state :: State.t()

  @spec start_link(product) :: GenServer.on_start()
  def start_link(product) do
    state = %State{venue: product.venue_id, symbol: product.symbol}
    name = to_name(product.venue_id, product.venue_symbol)

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec to_name(venue, venue_symbol) :: atom
  def to_name(venue, symbol), do: :"#{__MODULE__}_#{venue}_#{symbol}"

  @spec init(state) :: {:ok, state}
  def init(state), do: {:ok, state}

  def handle_cast(
        {
          :update,
          %{
            "bids" => bids,
            "asks" => asks,
            "timestamp" => timestamp,
            "change_id" => _change_id
          },
          received_at
        },
        state
      ) do
    state
    |> build_change_set(bids, asks, timestamp, received_at)
    |> OrderBook.replace()

    {:noreply, state}
  end

  defp build_change_set(state, bids, asks, timestamp, received_at) do
    {:ok, venue_timestamp} = timestamp |> DateTime.from_unix(:millisecond)
    normalized_bids = bids |> normalize_changes(:bid)
    normalized_asks = asks |> normalize_changes(:ask)

    %OrderBook.ChangeSet{
      venue: state.venue,
      symbol: state.symbol,
      last_venue_timestamp: venue_timestamp,
      last_received_at: received_at,
      changes: Enum.concat(normalized_bids, normalized_asks)
    }
  end

  defp normalize_changes(venue_price_points, side) do
    venue_price_points
    |> Enum.map(fn [price, size] ->
      {:upsert, side, price, size}
    end)
  end
end
