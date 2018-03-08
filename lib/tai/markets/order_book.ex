defmodule Tai.Markets.OrderBook do
  @moduledoc """
  Manage and query the state for an order book for a symbol on a feed
  """

  use GenServer

  def start_link(feed_id: feed_id, symbol: symbol) do
    GenServer.start_link(
      __MODULE__,
      %{bids: %{}, asks: %{}},
      name: to_name(feed_id: feed_id, symbol: symbol)
    )
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:quotes, depth: depth}, _from, state) do
    {
      :reply,
      {
        :ok,
        %{
          bids: state |> ordered_bids |> take(depth),
          asks: state |> ordered_asks |> take(depth)
        }
      },
      state
    }
  end

  def handle_call(:bid, _from, state) do
    {:reply, {:ok, state |> ordered_bids |> List.first}, state}
  end

  def handle_call({:bids, depth}, _from, state) do
    {:reply, {:ok, state |> ordered_bids |> take(depth)}, state}
  end

  def handle_call(:ask, _from, state) do
    {:reply, {:ok, state |> ordered_asks |> List.first}, state}
  end

  def handle_call({:asks, depth}, _from, state) do
    {:reply, {:ok, state |> ordered_asks |> take(depth)}, state}
  end

  def handle_call({:replace, replacement}, _from, _state) do
    {:reply, :ok, replacement}
  end

  def handle_call({:update, %{bids: bids, asks: asks}}, _from, state) do
    new_state = state
                |> update_side(:bids, bids)
                |> update_side(:asks, asks)

    {:reply, :ok, new_state}
  end

  def quotes(name, depth \\ :all) do
    GenServer.call(name, {:quotes, depth: depth})
  end

  def bid(name) do
    GenServer.call(name, :bid)
  end

  def bids(name, depth \\ :all) do
    GenServer.call(name, {:bids, depth})
  end

  def ask(name) do
    GenServer.call(name, :ask)
  end

  def asks(name, depth \\ :all) do
    GenServer.call(name, {:asks, depth})
  end

  def replace(name, %{bids: _b, asks: _a} = replacement) do
    GenServer.call(name, {:replace, replacement})
  end

  def update(name, %{bids: _b, asks: _a} = changes) do
    GenServer.call(name, {:update, changes})
  end

  @doc """
  Returns an atom that will identify the process

  ## Examples

    iex> Tai.Markets.OrderBook.to_name(feed_id: :my_test_feed, symbol: :btcusd)
    Tai.Markets.OrderBook_my_test_feed_btcusd
  """
  def to_name(feed_id: feed_id, symbol: symbol) do
    :"#{__MODULE__}_#{feed_id}_#{symbol}"
  end

  defp ordered_bids(state) do
    state.bids
    |> Map.keys
    |> Enum.sort
    |> Enum.reverse
    |> to_keyword_list(state.bids)
  end

  defp ordered_asks(state) do
    state.asks
    |> Map.keys
    |> Enum.sort
    |> to_keyword_list(state.asks)
  end

  defp to_keyword_list(prices, price_levels) do
    prices
    |> Enum.map(fn price ->
      {size, processed_at, server_changed_at} = price_levels[price]
      [price: price, size: size, processed_at: processed_at, server_changed_at: server_changed_at]
    end)
  end

  defp take(list, :all), do: list
  defp take(list, depth) do
    list
    |> Enum.take(depth)
  end

  defp update_side(state, side, price_levels) do
    new_side = state[side]
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
