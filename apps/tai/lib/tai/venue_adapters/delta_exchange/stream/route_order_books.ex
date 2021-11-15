defmodule Tai.VenueAdapters.DeltaExchange.Stream.RouteOrderBooks do
  use GenServer
  alias Tai.VenueAdapters.DeltaExchange.Stream.ProcessOrderBook

  defmodule State do
    @type venue_id :: Tai.Venue.id()
    @type venue_symbol :: Tai.Venues.Product.symbol()
    @type store_name :: atom
    @type stores :: %{optional(venue_symbol) => store_name}
    @type sequence_numbers :: %{optional(venue_symbol) => non_neg_integer | nil}
    @type t :: %State{
      venue: venue_id,
      stores: stores,
      sequence_numbers: sequence_numbers
    }

    @enforce_keys ~w[venue stores sequence_numbers]a
    defstruct ~w[venue stores sequence_numbers]a
  end

  @type venue_id :: Tai.Venue.id()
  @type product :: Tai.Venues.Product.t()
  @type state :: State.t()

  @spec start_link(venue: venue_id, order_books: [product]) :: GenServer.on_start()
  def start_link(venue: venue, order_books: order_books) do
    stores = order_books |> build_stores()
    sequence_numbers = order_books |> build_sequence_numbers()
    state = %State{venue: venue, stores: stores, sequence_numbers: sequence_numbers}
    name = venue |> to_name()

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_cast(
    {
      %{"type" => "l2_orderbook", "last_sequence_no" => last_sequence_no, "symbol" => venue_symbol, "buy" => buy, "sell" => sell},
      received_at
    },
    state
  ) do
    data = {buy, sell}

    {state, venue_symbol}
    |> forward({:snapshot, data, received_at})

    sequence_numbers = state.sequence_numbers |> Map.put(venue_symbol, last_sequence_no)
    state = %{state | sequence_numbers: sequence_numbers}
    {:noreply, state}
  end

  defp build_stores(order_books) do
    order_books
    |> Enum.reduce(
      %{},
      &Map.put(&2, &1.venue_symbol, &1.venue_id |> ProcessOrderBook.to_name(&1.venue_symbol))
    )
  end

  defp build_sequence_numbers(order_books) do
    order_books
    |> Enum.reduce(
      %{},
      &Map.put(&2, &1.venue_symbol, nil)
    )
  end

  defp forward({state, venue_symbol}, msg) do
    state.stores
    |> Map.fetch!(venue_symbol)
    |> GenServer.cast(msg)
  end
end
