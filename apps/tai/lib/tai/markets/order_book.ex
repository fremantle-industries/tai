defmodule Tai.Markets.OrderBook do
  @moduledoc """
  Manage price points for a venue's order book
  """

  use GenServer
  alias Tai.Markets.{OrderBook, PricePoint, Quote}

  defmodule ChangeSet do
    @type venue_id :: Tai.Venue.id()
    @type product_symbol :: Tai.Venues.Product.symbol()
    @type side :: :bid | :ask
    @type price :: number
    @type size :: number
    @type upsert :: {:upsert, side, price, size}
    @type delete :: {:delete, side, price}
    @type change :: upsert | delete
    @type t :: %ChangeSet{
            venue: venue_id,
            symbol: product_symbol,
            changes: [change],
            last_received_at: DateTime.t(),
            last_venue_timestamp: DateTime.t() | nil
          }

    @enforce_keys ~w(venue symbol changes last_received_at)a
    defstruct ~w(venue symbol changes last_received_at last_venue_timestamp)a
  end

  defmodule State do
    @type venue_id :: Tai.Venue.id()
    @type product :: Tai.Venues.Product.t()
    @type product_symbol :: Tai.Venues.Product.symbol()
    @type price :: number
    @type qty :: number
    @type quote_depth :: pos_integer
    @type market_quote :: Tai.Markets.Quote.t()
    @type t :: %State{
            broadcast_change_set: boolean,
            venue_id: venue_id,
            product_symbol: product_symbol,
            quote_depth: quote_depth,
            last_quote_bids: [{price, qty}],
            last_quote_asks: [{price, qty}],
            bids: %{optional(price) => qty},
            asks: %{optional(price) => qty}
          }

    @enforce_keys ~w(
      venue_id
      product_symbol
      quote_depth
      last_quote_bids
      last_quote_asks
      bids
      asks
    )a
    defstruct ~w(
      broadcast_change_set
      venue_id
      product_symbol
      quote_depth
      last_quote_bids
      last_quote_asks
      bids
      asks
    )a
  end

  @type t :: State.t()
  @type venue_id :: Tai.Venue.id()
  @type product :: Tai.Venues.Product.t()
  @type product_symbol :: Tai.Venues.Product.symbol()
  @type quote_depth :: State.quote_depth()

  @spec child_spec(product, quote_depth, boolean) :: Supervisor.child_spec()
  def child_spec(product, quote_depth, broadcast_change_set) do
    %{
      id: to_name(product.venue_id, product.symbol),
      start: {
        __MODULE__,
        :start_link,
        [[product: product, quote_depth: quote_depth, broadcast_change_set: broadcast_change_set]]
      }
    }
  end

  @spec start_link(product: product, quote_depth: quote_depth, broadcast_change_set: boolean) ::
          GenServer.on_start()
  def start_link(
        product: product,
        quote_depth: quote_depth,
        broadcast_change_set: broadcast_change_set
      ) do
    name = to_name(product.venue_id, product.symbol)

    state = %State{
      venue_id: product.venue_id,
      product_symbol: product.symbol,
      quote_depth: quote_depth,
      last_quote_bids: [],
      last_quote_asks: [],
      bids: %{},
      asks: %{},
      broadcast_change_set: broadcast_change_set
    }

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec to_name(venue_id, product_symbol) :: atom
  def to_name(venue, symbol), do: :"#{__MODULE__}_#{venue}_#{symbol}"

  @spec replace(ChangeSet.t()) :: :ok
  def replace(%OrderBook.ChangeSet{} = change_set) do
    change_set.venue
    |> OrderBook.to_name(change_set.symbol)
    |> GenServer.cast({:replace, change_set})
  end

  @spec apply(ChangeSet.t()) :: term
  def apply(%ChangeSet{} = change_set) do
    change_set.venue
    |> OrderBook.to_name(change_set.symbol)
    |> GenServer.cast({:apply, change_set})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:replace, change_set}, state) do
    {bids, asks} =
      state
      |> delete_all
      |> apply_changes(change_set.changes)
      |> latest

    market_quote = build_market_quote(change_set, bids, asks)
    {:ok, _} = Tai.Markets.QuoteStore.put(market_quote)
    state = %{state | last_quote_bids: bids, last_quote_asks: asks}

    if state.broadcast_change_set do
      {:noreply, state, {:continue, {:broadcast_change_set, change_set}}}
    else
      {:noreply, state}
    end
  end

  def handle_cast({:apply, change_set}, state) do
    {bids, asks} =
      state
      |> apply_changes(change_set.changes)
      |> latest

    state =
      if market_quote_changed?(bids, asks, state) do
        market_quote = build_market_quote(change_set, bids, asks)
        {:ok, _} = Tai.Markets.QuoteStore.put(market_quote)
        %{state | last_quote_bids: bids, last_quote_asks: asks}
      else
        state
      end

    if state.broadcast_change_set do
      {:noreply, state, {:continue, {:broadcast_change_set, change_set}}}
    else
      {:noreply, state}
    end
  end

  def handle_continue({:broadcast_change_set, change_set}, state) do
    msg = {:change_set, change_set}

    {:change_set, state.venue_id, state.product_symbol}
    |> Tai.SystemBus.broadcast(msg)

    :change_set
    |> Tai.SystemBus.broadcast(msg)

    {:noreply, state}
  end

  defp delete_all(state) do
    %{state | bids: %{}, asks: %{}}
  end

  defp apply_changes(state, changes) do
    changes
    |> Enum.reduce(
      state,
      fn
        {:upsert, :bid, price, size}, acc ->
          new_bids = acc.bids |> Map.put(price, size)
          Map.put(acc, :bids, new_bids)

        {:upsert, :ask, price, size}, acc ->
          new_bids = acc.asks |> Map.put(price, size)
          Map.put(acc, :asks, new_bids)

        {:delete, :bid, price}, acc ->
          new_bids = acc.bids |> Map.delete(price)
          Map.put(acc, :bids, new_bids)

        {:delete, :ask, price}, acc ->
          new_asks = acc.asks |> Map.delete(price)
          Map.put(acc, :asks, new_asks)
      end
    )
  end

  defp latest(state) do
    {latest_bids(state), latest_asks(state)}
  end

  defp latest_bids(state) do
    state.bids
    |> Map.keys()
    |> Enum.sort(&(&1 > &2))
    |> Enum.take(state.quote_depth)
    |> Enum.map(fn p -> {p, Map.get(state.bids, p)} end)
  end

  defp latest_asks(state) do
    state.asks
    |> Map.keys()
    |> Enum.sort(&(&1 < &2))
    |> Enum.take(state.quote_depth)
    |> Enum.map(fn p -> {p, Map.get(state.asks, p)} end)
  end

  defp market_quote_changed?(bids, asks, state) do
    bids != state.last_quote_bids || asks != state.last_quote_asks
  end

  defp build_market_quote(change_set, bids, asks) do
    %Quote{
      venue_id: change_set.venue,
      product_symbol: change_set.symbol,
      last_venue_timestamp: change_set.last_venue_timestamp,
      last_received_at: change_set.last_received_at,
      bids: price_points(bids),
      asks: price_points(asks)
    }
  end

  defp price_points(side) do
    Enum.map(side, fn {p, s} -> %PricePoint{price: p, size: s} end)
  end
end
