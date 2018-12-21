defmodule Tai.Markets.OrderBook do
  @moduledoc """
  Manage and query the state for an order book for a symbol on a feed
  """

  use GenServer
  alias Tai.{Markets, PubSub}

  @type t :: %Markets.OrderBook{
          venue_id: atom,
          product_symbol: atom,
          bids: map,
          asks: map
        }

  @enforce_keys [
    :venue_id,
    :product_symbol,
    :bids,
    :asks
  ]
  defstruct [
    :venue_id,
    :product_symbol,
    :bids,
    :asks
  ]

  def start_link(feed_id: venue_id, symbol: product_symbol) do
    name = to_name(venue_id, product_symbol)

    order_book = %Markets.OrderBook{
      venue_id: venue_id,
      product_symbol: product_symbol,
      bids: %{},
      asks: %{}
    }

    GenServer.start_link(__MODULE__, order_book, name: name)
  end

  def init(state), do: {:ok, state}

  def handle_call({:quotes, depth: depth}, _from, state) do
    order_book = %Markets.OrderBook{
      venue_id: state.venue_id,
      product_symbol: state.product_symbol,
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

    Tai.Events.broadcast(%Tai.Events.OrderBookSnapshot{
      venue_id: snapshot.venue_id,
      symbol: snapshot.product_symbol,
      snapshot: snapshot
    })

    {:reply, :ok, snapshot}
  end

  def handle_call({:update, %Markets.OrderBook{bids: bids, asks: asks} = changes}, _from, state) do
    PubSub.broadcast(
      {:order_book_changes, state.venue_id, state.product_symbol},
      {:order_book_changes, state.venue_id, state.product_symbol, changes}
    )

    new_state =
      state
      |> update_side(:bids, bids)
      |> update_side(:asks, asks)

    {:reply, :ok, new_state}
  end

  @doc """
  Return bid/asks up to the given depth. If depth is not provided it returns
  the full order book.
  """
  def quotes(name, depth \\ :all) do
    GenServer.call(name, {:quotes, depth: depth})
  end

  @doc """
  Return the bid/ask at the top of the book
  """
  def inside_quote(feed_id, symbol) do
    name = to_name(feed_id, symbol)

    name
    |> quotes(1)
    |> case do
      {:ok, %{bids: bids, asks: asks}} ->
        with top_bid <- List.first(bids),
             top_ask <- List.first(asks) do
          {:ok, %Markets.Quote{bid: top_bid, ask: top_ask}}
        end
    end
  end

  def replace(name, %Markets.OrderBook{} = replacement) do
    GenServer.call(name, {:replace, replacement})
  end

  def update(name, %Markets.OrderBook{} = changes) do
    GenServer.call(name, {:update, changes})
  end

  @spec to_name(atom, atom) :: atom
  def to_name(venue_id, product_symbol) do
    :"#{__MODULE__}_#{venue_id}_#{product_symbol}"
  end

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

      %Markets.PriceLevel{
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
