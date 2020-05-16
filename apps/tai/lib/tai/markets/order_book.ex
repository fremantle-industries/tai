defmodule Tai.Markets.OrderBook do
  @moduledoc """
  Manage price points for the order book of a product
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
            last_received_at: integer,
            last_venue_timestamp: DateTime.t() | nil
          }

    @enforce_keys ~w[venue symbol changes last_received_at]a
    defstruct ~w[venue symbol changes last_received_at last_venue_timestamp]a
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
            venue: venue_id,
            symbol: product_symbol,
            quote_depth: quote_depth,
            bids_table: atom,
            asks_table: atom,
            last_quote_bids: [{price, qty}],
            last_quote_asks: [{price, qty}]
          }

    @enforce_keys ~w(
      venue
      symbol
      quote_depth
      bids_table
      asks_table
      last_quote_bids
      last_quote_asks
    )a
    defstruct ~w(
      broadcast_change_set
      venue
      symbol
      quote_depth
      bids_table
      asks_table
      last_quote_bids
      last_quote_asks
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
      venue: product.venue_id,
      symbol: product.symbol,
      quote_depth: quote_depth,
      bids_table: table_name(:bids, product),
      asks_table: table_name(:asks, product),
      last_quote_bids: [],
      last_quote_asks: [],
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
    create_price_point_ets_table(state.bids_table)
    create_price_point_ets_table(state.asks_table)
    {:ok, state}
  end

  def handle_cast({:replace, change_set}, state) do
    {bids, asks} =
      state
      |> delete_all
      |> apply_changes(change_set.changes)
      |> latest_quote

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
      |> latest_quote

    state =
      if market_quote_changed?(
           {state.last_quote_bids, bids},
           {state.last_quote_asks, asks}
         ) do
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

    {:change_set, state.venue, state.symbol}
    |> Tai.SystemBus.broadcast(msg)

    :change_set
    |> Tai.SystemBus.broadcast(msg)

    {:noreply, state}
  end

  defp create_price_point_ets_table(name) do
    :ets.new(name, [:ordered_set, :protected, :named_table])
  end

  defp table_name(side, product) do
    :"#{__MODULE__}_#{product.venue_id}_#{product.symbol}_#{side}"
  end

  defp delete_all(state) do
    :ets.delete_all_objects(state.bids_table)
    :ets.delete_all_objects(state.asks_table)
    state
  end

  defp apply_changes(state, changes) do
    changes
    |> Enum.each(fn
      {:upsert, :bid, price, size} ->
        true = :ets.insert(state.bids_table, {price, size})

      {:upsert, :ask, price, size} ->
        true = :ets.insert(state.asks_table, {price, size})

      {:delete, :bid, price} ->
        true = :ets.delete(state.bids_table, price)

      {:delete, :ask, price} ->
        true = :ets.delete(state.asks_table, price)
    end)

    state
  end

  @select_all [{:"$1", [], [:"$1"]}]
  defp latest_quote(state) do
    {latest_bids(state), latest_asks(state)}
  end

  defp latest_bids(state) do
    state.bids_table
    |> :ets.select_reverse(@select_all, state.quote_depth)
    |> case do
      {bids, _continuation} -> bids
      :"$end_of_table" -> []
    end
  end

  defp latest_asks(state) do
    state.asks_table
    |> :ets.select(@select_all, state.quote_depth)
    |> case do
      {asks, _continuation} -> asks
      :"$end_of_table" -> []
    end
  end

  defp market_quote_changed?({prev_bids, latest_bids}, {prev_asks, latest_asks}) do
    prev_bids != latest_bids || prev_asks != latest_asks
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
