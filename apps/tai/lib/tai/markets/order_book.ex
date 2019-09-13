defmodule Tai.Markets.OrderBook do
  @moduledoc """
  Manage price points of an order book on a venue
  """

  use GenServer
  alias Tai.Markets.{OrderBook, PriceLevel, Quote}
  alias Tai.PubSub

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type product_symbol :: Tai.Venues.Product.symbol()
  @type t :: %OrderBook{
          venue_id: venue_id,
          product_symbol: product_symbol,
          bids: map,
          asks: map,
          last_received_at: DateTime.t() | nil,
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

  def start_link(venue: venue_id, symbol: product_symbol) do
    name = to_name(venue_id, product_symbol)

    state = %OrderBook{
      venue_id: venue_id,
      product_symbol: product_symbol,
      bids: %{},
      asks: %{}
    }

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @deprecated "Use Tai.Markets.OrderBook.start_link(venue: _, symbol: _) instead."
  def start_link(feed_id: venue_id, symbol: product_symbol) do
    start_link(venue: venue_id, symbol: product_symbol)
  end

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

  def handle_call({:replace, snapshot}, _from, _state) do
    PubSub.broadcast(
      {:order_book_snapshot, snapshot.venue_id, snapshot.product_symbol},
      {:order_book_snapshot, snapshot.venue_id, snapshot.product_symbol, snapshot}
    )

    Tai.Events.debug(%Tai.Events.OrderBookSnapshot{
      venue_id: snapshot.venue_id,
      symbol: snapshot.product_symbol,
      snapshot: snapshot
    })

    {:reply, :ok, snapshot}
  end

  def handle_call({:update, %OrderBook{bids: bids, asks: asks} = changes}, _from, state) do
    PubSub.broadcast(
      {:order_book_changes, state.venue_id, state.product_symbol},
      {:order_book_changes, state.venue_id, state.product_symbol, changes}
    )

    new_state =
      state
      |> update_side(:bids, bids)
      |> update_side(:asks, asks)
      |> Map.put(:last_received_at, changes.last_received_at)
      |> Map.put(:last_venue_timestamp, changes.last_venue_timestamp)

    {:reply, :ok, new_state}
  end

  @doc """
  Return bid/asks up to the given depth. If depth is not provided it returns
  the full order book.
  """
  def quotes(name, depth \\ :all), do: GenServer.call(name, {:quotes, depth: depth})

  @doc """
  Return the bid/ask at the top of the book
  """
  @spec inside_quote(atom, atom) :: {:ok, Quote.t()}
  def inside_quote(venue_id, product_symbol) do
    name = to_name(venue_id, product_symbol)

    name
    |> quotes(1)
    |> case do
      {:ok, book} ->
        inside_bid = List.first(book.bids)
        inside_ask = List.first(book.asks)

        q = %Quote{
          venue_id: venue_id,
          product_symbol: product_symbol,
          last_received_at: book.last_received_at,
          last_venue_timestamp: book.last_venue_timestamp,
          bid: inside_bid,
          ask: inside_ask
        }

        {:ok, q}
    end
  end

  @spec replace(t) :: :ok
  def replace(%OrderBook{} = replacement) do
    replacement.venue_id
    |> OrderBook.to_name(replacement.product_symbol)
    |> GenServer.call({:replace, replacement})
  end

  @spec update(t) :: :ok
  def update(%OrderBook{} = changes) do
    changes.venue_id
    |> OrderBook.to_name(changes.product_symbol)
    |> GenServer.call({:update, changes})
  end

  @spec to_name(atom, atom) :: atom
  def to_name(venue_id, product_symbol), do: :"#{__MODULE__}_#{venue_id}_#{product_symbol}"

  defp ordered_bids(state) do
    state.bids
    |> Map.keys()
    |> Enum.sort()
    |> Enum.reverse()
    |> with_price_levels(state.bids)
  end

  defp ordered_asks(state) do
    state.asks
    |> Map.keys()
    |> Enum.sort()
    |> with_price_levels(state.asks)
  end

  defp with_price_levels(prices, level_details) do
    prices
    |> Enum.map(fn price ->
      {size, processed_at, server_changed_at} = level_details[price]

      %PriceLevel{
        price: price,
        size: size,
        processed_at: processed_at,
        server_changed_at: server_changed_at
      }
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
    |> Enum.filter(fn {_price, {size, _processed_at, _server_changed_at}} -> size == 0 end)
    |> Enum.map(fn {price, _} -> price end)
  end
end
