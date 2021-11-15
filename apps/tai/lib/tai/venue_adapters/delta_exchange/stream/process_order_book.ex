defmodule Tai.VenueAdapters.DeltaExchange.Stream.ProcessOrderBook do
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

  defp build_change_set({{bids, asks}, received_at, state}) do
    normalized_bids = bids |> normalize_changes(:bid)
    normalized_asks = asks |> normalize_changes(:ask)

    %OrderBook.ChangeSet{
      venue: state.venue,
      symbol: state.symbol,
      last_received_at: received_at,
      changes: Enum.concat(normalized_bids, normalized_asks)
    }
  end

  defp normalize_changes(data, :bid), do: data |> normalize_side(:bid)
  defp normalize_changes(data, :ask), do: data |> normalize_side(:ask)

  defp normalize_side(data, side) do
    data
    |> Enum.map(fn
      %{"limit_price" => raw_price, "size" => size} ->
        {price, _} = Float.parse(raw_price)
        {:upsert, side, price, size}
    end)
  end
end
