defmodule Tai.Advisor do
  @moduledoc """
  A behavior for implementing a server that receives order book changes.

  It can be used to monitor multiple quote streams and create, update or cancel orders.
  """

  alias Tai.{PubSub, Markets.OrderBook, Trading.Order}

  @doc """
  Callback when order book has bid or ask changes
  """
  @callback handle_order_book_changes(feed_id :: Atom.t, symbol :: Atom.t, changes :: term, state :: Map.t) :: :ok

  @doc """
  Callback when the highest bid or lowest ask changes price or size
  """
  @callback handle_inside_quote(feed_id :: Atom.t, symbol :: Atom.t, bid :: Map.t, ask :: Map.t, snapshot_or_changes :: Map.t | List.t, state :: Map.t) :: :ok | {:ok, actions :: Map.t}

  @doc """
  Callback when an order is enqueued
  """
  @callback handle_order_enqueued(order :: Order.t, state :: Map.t) :: :ok

  @doc """
  Callback when an order is created on the server
  """
  @callback handle_order_create_ok(order :: Order.t, state :: Map.t) :: :ok

  @doc """
  Callback when an order creation fails
  """
  @callback handle_order_create_error(reason :: term, order :: Order.t, state :: Map.t) :: :ok

  @doc """
  Returns an atom that will identify the process

  ## Examples

    iex> Tai.Advisor.to_name(:my_test_advisor)
    :advisor_my_test_advisor
  """
  def to_name(advisor_id), do: :"advisor_#{advisor_id}"

  defmacro __using__(_) do
    quote location: :keep do
      use GenServer

      require Logger
      require Tai.TimeFrame

      alias Tai.{Advisor, Markets.OrderBook, Trading.OrderOutbox}

      @behaviour Advisor

      def start_link(advisor_id: advisor_id, order_book_feed_ids: order_book_feed_ids) do
        GenServer.start_link(
          __MODULE__,
          %{
            advisor_id: advisor_id,
            order_book_feed_ids: order_book_feed_ids,
            inside_quotes: %{}
          },
          name: advisor_id |> Advisor.to_name
        )
      end

      @doc false
      def init(%{order_book_feed_ids: order_book_feed_ids} = state) do
        order_book_feed_ids
        |> subscribe_to_internal_channels

        {:ok, state}
      end

      @doc false
      def handle_info({:order_book_snapshot, feed_id, symbol, normalized_bids, normalized_asks}, state) do
        new_state = state
                    |> cache_inside_quote(feed_id, symbol)
                    |> execute_handle_inside_quote(feed_id, symbol, %{bids: normalized_bids, asks: normalized_asks})

        {:noreply, new_state}
      end
      @doc false
      def handle_info({:order_book_changes, feed_id, symbol, changes} = msg, state) do
        new_state = Tai.TimeFrame.debug "[#{state.advisor_id |> Advisor.to_name}] handle_info({:order_book_changes...})" do
          handle_order_book_changes(feed_id, symbol, changes, state)

          previous_inside_quote = state |> cached_inside_quote(feed_id, symbol)
          if previous_inside_quote |> inside_quote_is_stale?(changes) do
            state
            |> cache_inside_quote(feed_id, symbol)
            |> execute_handle_inside_quote(feed_id, symbol, changes, previous_inside_quote)
          else
            state
          end
        end

        {:noreply, new_state}
      end
      @doc false
      def handle_info({:order_enqueued, order} = msg, state) do
        handle_order_enqueued(order, state)

        {:noreply, state}
      end
      @doc false
      def handle_info({:order_create_ok, order} = msg, state) do
        handle_order_create_ok(order, state)

        {:noreply, state}
      end
      @doc false
      def handle_info({:order_create_error, reason, order} = msg, state) do
        handle_order_create_error(reason, order, state)

        {:noreply, state}
      end

      @doc """
      Returns the current state of the order book up to the given depth

      ## Examples

        iex> Tai.Advisor.quotes(feed_id: :test_feed_a, symbol: :btcusd, depth: 1)
        {:ok, %{bids: [], asks: []}
      """
      def quotes(feed_id: feed_id, symbol: symbol, depth: depth) do
        [feed_id: feed_id, symbol: symbol]
        |> OrderBook.to_name
        |> OrderBook.quotes(depth)
      end

      defp subscribe_to_internal_channels([]), do: nil
      defp subscribe_to_internal_channels([feed_id | tail]) do
        PubSub.subscribe({:order_book_changes, feed_id})
        PubSub.subscribe({:order_book_snapshot, feed_id})
        PubSub.subscribe(:order_enqueued)
        PubSub.subscribe(:order_create_ok)
        PubSub.subscribe(:order_create_error)

        tail
        |> subscribe_to_internal_channels
      end

      defp inside_quote(feed_id, symbol) do
        [feed_id: feed_id, symbol: symbol, depth: 1]
        |> quotes
        |> case do
          {:ok, %{bids: bids, asks: asks}} -> [bid: bids |> List.first, ask: asks |> List.first]
        end
      end

      defp cache_inside_quote(state, feed_id, symbol) do
        current_inside_quote = inside_quote(feed_id, symbol)
        order_book_key = [feed_id: feed_id, symbol: symbol] |> OrderBook.to_name
        new_inside_quotes = state.inside_quotes |> Map.put(order_book_key, current_inside_quote)

        state |> Map.put(:inside_quotes, new_inside_quotes)
      end

      defp cached_inside_quote(%{inside_quotes: inside_quotes}, feed_id, symbol) do
        inside_quotes
        |> Map.get([feed_id: feed_id, symbol: symbol] |> OrderBook.to_name)
      end

      defp inside_quote_is_stale?(previous_inside_quote, %{bids: bids, asks: asks} = changes) do
        (bids |> Enum.any? && bids |> inside_bid_is_stale?(previous_inside_quote)) || (asks |> Enum.any? && asks |> inside_ask_is_stale?(previous_inside_quote))
      end

      defp inside_bid_is_stale?(bids, nil), do: false
      defp inside_bid_is_stale?(bids, [bid: [price: prev_bid_price, size: prev_bid_size, processed_at: _pa, server_changed_at: _sca], ask: ask]) do
        bids
        |> Enum.any?(fn {price, {size, _processed_at, _server_changed_at}} ->
          price >= prev_bid_price || (price == prev_bid_price && size != prev_bid_size)
        end)
      end

      defp inside_ask_is_stale?(asks, nil), do: false
      defp inside_ask_is_stale?(asks, [bid: bid, ask: [price: prev_ask_price, size: prev_ask_size, processed_at: _pa, server_changed_at: _sca]]) do
        asks
        |> Enum.any?(fn {price, {size, _processed_at, _server_changed_at}} ->
          price <= prev_ask_price || (price == prev_ask_price && size != prev_ask_size)
        end)
      end

      defp execute_handle_inside_quote(state, feed_id, symbol, snapshot_or_changes, previous_inside_quote \\ nil) do
        [bid: inside_bid, ask: inside_ask] = current_inside_quote = state |> cached_inside_quote(feed_id, symbol)

        unless current_inside_quote == previous_inside_quote do
          handle_inside_quote(feed_id, symbol, inside_bid, inside_ask, snapshot_or_changes, state)
          |> submit_orders
        end

        state
      end

      defp submit_orders(:ok), do: []
      defp submit_orders({:ok, %{limit_orders: limit_orders}}) do
        limit_orders
        |> OrderOutbox.add
      end
    end
  end
end
