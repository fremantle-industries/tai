defmodule Tai.Markets.OrderBook do
  @moduledoc """
  Manage price points for a venue's order book
  """

  use GenServer
  alias Tai.Markets.{OrderBook, PricePoint, Quote}
  alias Tai.PubSub

  defmodule ChangeSet do
    @type venue_id :: Tai.Venues.Adapter.venue_id()
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

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type product :: Tai.Venues.Product.t()
  @type product_symbol :: Tai.Venues.Product.symbol()
  @type t :: %OrderBook{
          venue_id: venue_id,
          product_symbol: product_symbol,
          bids: %{(price :: number) => size :: pos_integer},
          asks: %{(price :: number) => size :: pos_integer},
          last_received_at: DateTime.t(),
          last_venue_timestamp: DateTime.t() | nil
        }

  @enforce_keys ~w(
    venue_id
    product_symbol
    bids
    asks
  )a
  defstruct ~w(
    venue_id
    product_symbol
    bids
    asks
    last_received_at
    last_venue_timestamp
  )a

  @spec start_link(product) :: GenServer.on_start()
  def start_link(product) do
    name = to_name(product.venue_id, product.symbol)

    state = %OrderBook{
      venue_id: product.venue_id,
      product_symbol: product.symbol,
      bids: %{},
      asks: %{}
    }

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec replace(t | ChangeSet.t()) :: :ok
  def replace(snapshot_or_change_set)

  def replace(%OrderBook{} = snapshot) do
    snapshot.venue_id
    |> OrderBook.to_name(snapshot.product_symbol)
    |> GenServer.call({:replace, snapshot})
  end

  def replace(%OrderBook.ChangeSet{} = change_set) do
    change_set.venue
    |> OrderBook.to_name(change_set.symbol)
    |> GenServer.cast({:replace, change_set})
  end

  @spec update(t) :: :ok
  def update(%OrderBook{} = changes) do
    changes.venue_id
    |> OrderBook.to_name(changes.product_symbol)
    |> GenServer.call({:update, changes})
  end

  @spec apply(ChangeSet.t()) :: term
  def apply(%ChangeSet{} = change_set) do
    change_set.venue
    |> OrderBook.to_name(change_set.symbol)
    |> GenServer.cast({:apply, change_set})
  end

  @doc """
  Return bid/asks up to the given depth. If depth is not provided it returns
  the full order book.
  """
  def quotes(name, depth \\ :all), do: GenServer.call(name, {:quotes, depth: depth})

  @doc """
  Return the bid/ask at the top of the book
  """
  @spec inside_quote(venue_id, product_symbol) :: {:ok, Quote.t()}
  def inside_quote(venue, symbol) do
    name = to_name(venue, symbol)

    name
    |> quotes(1)
    |> case do
      {:ok, book} ->
        inside_bid = List.first(book.bids)
        inside_ask = List.first(book.asks)

        q = %Quote{
          venue_id: venue,
          product_symbol: symbol,
          last_received_at: book.last_received_at,
          last_venue_timestamp: book.last_venue_timestamp,
          bid: inside_bid,
          ask: inside_ask
        }

        {:ok, q}
    end
  end

  @spec to_name(venue_id, product_symbol) :: atom
  def to_name(venue, symbol), do: :"#{__MODULE__}_#{venue}_#{symbol}"

  def init(state), do: {:ok, state}

  def handle_call({:quotes, depth: depth}, _from, state) do
    order_book = %OrderBook{
      venue_id: state.venue_id,
      product_symbol: state.product_symbol,
      last_received_at: state.last_received_at,
      last_venue_timestamp: state.last_venue_timestamp,
      bids: state |> ordered_bids |> take(depth),
      asks: state |> ordered_asks |> take(depth)
    }

    {:reply, {:ok, order_book}, state}
  end

  def handle_call({:replace, %OrderBook{} = snapshot}, _from, _state) do
    PubSub.broadcast(
      {:order_book_snapshot, snapshot.venue_id, snapshot.product_symbol},
      {:order_book_snapshot, snapshot.venue_id, snapshot.product_symbol, snapshot}
    )

    Tai.Events.debug(%Tai.Events.OrderBookSnapshot{
      venue_id: snapshot.venue_id,
      symbol: snapshot.product_symbol
    })

    {:reply, :ok, snapshot}
  end

  def handle_call({:update, changes}, _from, state) do
    PubSub.broadcast(
      {:order_book_changes, state.venue_id, state.product_symbol},
      {:order_book_changes, state.venue_id, state.product_symbol, changes}
    )

    new_state =
      state
      |> update_side(:bids, changes.bids)
      |> update_side(:asks, changes.asks)
      |> Map.put(:last_received_at, changes.last_received_at)
      |> Map.put(:last_venue_timestamp, changes.last_venue_timestamp)

    Tai.Events.debug(%Tai.Events.OrderBookUpdate{
      venue_id: state.venue_id,
      symbol: state.product_symbol
    })

    {:reply, :ok, new_state}
  end

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

    change_set.venue
    |> Tai.Markets.ProcessQuote.to_name(change_set.symbol)
    |> GenServer.cast({:order_book_snapshot, new_state, change_set})

    {:noreply, new_state}
  end

  def handle_cast({:apply, change_set}, state) do
    new_state =
      %{
        state
        | last_received_at: change_set.last_received_at,
          last_venue_timestamp: change_set.last_venue_timestamp
      }
      |> apply_changes(change_set.changes)

    change_set.venue
    |> Tai.Markets.ProcessQuote.to_name(change_set.symbol)
    |> GenServer.cast({:order_book_apply, new_state, change_set})

    {:noreply, new_state}
  end

  defp apply_changes(book, changes) do
    changes
    |> Enum.reduce(
      book,
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

  defp ordered_bids(state) do
    state.bids
    |> Map.keys()
    |> Enum.sort()
    |> Enum.reverse()
    |> with_price_points(state.bids)
  end

  defp ordered_asks(state) do
    state.asks
    |> Map.keys()
    |> Enum.sort()
    |> with_price_points(state.asks)
  end

  defp with_price_points(prices, levels) do
    prices
    |> Enum.map(fn price ->
      size = levels[price]
      %PricePoint{price: price, size: size}
    end)
  end

  defp take(list, :all), do: list

  defp take(list, depth) do
    list
    |> Enum.take(depth)
  end

  defp update_side(state, side, price_levels) do
    new_side =
      state
      |> Map.get(side)
      |> Map.merge(price_levels)
      |> Map.drop(price_levels |> drop_prices)

    state
    |> Map.put(side, new_side)
  end

  defp drop_prices(price_levels) do
    price_levels
    |> Enum.filter(fn {_, size} -> size == 0 end)
    |> Enum.map(fn {price, _} -> price end)
  end
end
