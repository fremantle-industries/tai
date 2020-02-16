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
            bids: %{optional(price) => qty},
            asks: %{optional(price) => qty},
            quote_depth: quote_depth,
            last_market_quote: market_quote | nil,
            last_received_at: DateTime.t(),
            last_venue_timestamp: DateTime.t() | nil
          }

    @enforce_keys ~w(
      venue_id
      product_symbol
      bids
      asks
      quote_depth
    )a
    defstruct ~w(
      broadcast_change_set
      venue_id
      product_symbol
      bids
      asks
      quote_depth
      last_market_quote
      last_received_at
      last_venue_timestamp
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

  @spec start_link(
          product: product,
          quote_depth: quote_depth,
          broadcast_change_set: boolean
        ) :: GenServer.on_start()
  def start_link(
        product: product,
        quote_depth: quote_depth,
        broadcast_change_set: broadcast_change_set
      ) do
    name = to_name(product.venue_id, product.symbol)

    state = %State{
      venue_id: product.venue_id,
      product_symbol: product.symbol,
      bids: %{},
      asks: %{},
      quote_depth: quote_depth,
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

  def init(state), do: {:ok, state}

  def handle_cast({:replace, %OrderBook.ChangeSet{} = change_set}, state) do
    new_state =
      %{
        state
        | bids: %{},
          asks: %{},
          last_received_at: change_set.last_received_at,
          last_venue_timestamp: change_set.last_venue_timestamp
      }
      |> apply_changes(change_set.changes)
      |> calculate_market_quote(change_set)

    {:ok, _} = Tai.Markets.QuoteStore.put(new_state.last_market_quote)

    if new_state.broadcast_change_set do
      {:noreply, new_state, {:continue, {:broadcast_change_set, change_set}}}
    else
      {:noreply, new_state}
    end
  end

  def handle_cast({:apply, change_set}, state) do
    last_market_quote = state.last_market_quote

    new_state =
      %{
        state
        | last_received_at: change_set.last_received_at,
          last_venue_timestamp: change_set.last_venue_timestamp
      }
      |> apply_changes(change_set.changes)
      |> calculate_market_quote(change_set)

    if market_quote_changed?(last_market_quote, new_state.last_market_quote) do
      {:ok, _} = Tai.Markets.QuoteStore.put(new_state.last_market_quote)
    end

    if new_state.broadcast_change_set do
      {:noreply, new_state, {:continue, {:broadcast_change_set, change_set}}}
    else
      {:noreply, new_state}
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

  defp calculate_market_quote(state, change_set) do
    bids = price_points(state.bids, state.quote_depth, &(&1 > &2))
    asks = price_points(state.asks, state.quote_depth, &(&1 < &2))

    market_quote = %Quote{
      venue_id: state.venue_id,
      product_symbol: state.product_symbol,
      last_venue_timestamp: change_set.last_venue_timestamp,
      last_received_at: change_set.last_received_at,
      bids: bids,
      asks: asks
    }

    Map.put(state, :last_market_quote, market_quote)
  end

  defp price_points(side, quote_depth, sort_by) do
    side
    |> Map.keys()
    |> Enum.sort(sort_by)
    |> Enum.take(quote_depth)
    |> Enum.map(&%PricePoint{price: &1, size: side |> Map.fetch!(&1)})
  end

  defp market_quote_changed?(nil, %Quote{}), do: true

  defp market_quote_changed?(current_market_quote, new_market_quote) do
    inside_price_point_changed?(current_market_quote.bids, new_market_quote.bids) ||
      inside_price_point_changed?(current_market_quote.asks, new_market_quote.asks)
  end

  defp inside_price_point_changed?(current, new) do
    current |> List.first() != new |> List.first()
  end
end
