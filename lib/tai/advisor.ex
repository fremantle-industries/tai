defmodule Tai.Advisor do
  @moduledoc """
  A behavior for implementing a server that receives order book changes.

  It can be used to monitor multiple quote streams and create, update or cancel orders.
  """

  @doc """
  Callback when order book has bid or ask changes
  """
  @callback handle_order_book_changes(feed_id :: Atom.t, symbol :: Atom.t, changes :: term, state :: Map.t) :: :ok

  @doc """
  Callback when the highest bid or lowest ask changes price or size
  """
  @callback handle_inside_quote(feed_id :: Atom.t, symbol :: Atom.t, bid :: Map.t, ask :: Map.t, snapshot_or_changes :: Map.t | List.t, state :: Map.t) :: :ok

  alias Tai.PubSub

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

      alias Tai.{Advisor, Markets.OrderBook}

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
        |> subscribe_to_order_book_channels

        {:ok, state}
      end

      @doc false
      def handle_info({:order_book_snapshot, feed_id, symbol, normalized_bids, normalized_asks}, state) do
        new_state = inside_quote(feed_id, symbol)
                    |> put_inside_quote_in_state(feed_id, symbol, state)
                    |> call_handle_inside_quote(feed_id, symbol, %{bids: normalized_bids, asks: normalized_asks})

        {:noreply, new_state}
      end
      @doc false
      def handle_info({:order_book_changes, feed_id, symbol, changes} = msg, state) do
        new_state = Tai.TimeFrame.debug "[#{state.advisor_id |> Advisor.to_name}] handle_info({:order_book_changes...})" do
          handle_order_book_changes(feed_id, symbol, changes, state)

          previous_inside_quote = state
                                  |> inside_quote_from_state(feed_id, symbol)
          if changes |> changed_inside_quote?(previous_inside_quote) do
            inside_quote(feed_id, symbol)
            |> put_inside_quote_in_state(feed_id, symbol, state)
            |> call_handle_inside_quote_if_changed(feed_id, symbol, changes, previous_inside_quote)
          else
            state
          end
        end

        {:noreply, new_state}
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

      defp subscribe_to_order_book_channels([]), do: nil
      defp subscribe_to_order_book_channels([feed_id | tail]) do
        PubSub.subscribe({:order_book_changes, feed_id})
        PubSub.subscribe({:order_book_snapshot, feed_id})

        tail
        |> subscribe_to_order_book_channels
      end

      defp inside_quote(feed_id, symbol) do
        [feed_id: feed_id, symbol: symbol, depth: 1]
        |> quotes
        |> case do
          {:ok, %{bids: bids, asks: asks}} -> [bid: bids |> List.first, ask: asks |> List.first]
        end
      end

      defp put_inside_quote_in_state(inside_quote, feed_id, symbol, state) do
        key = [feed_id: feed_id, symbol: symbol] |> OrderBook.to_name
        new_inside_quote = state.inside_quotes |> Map.put(key, inside_quote)

        state |> Map.put(:inside_quotes, new_inside_quote)
      end

      defp inside_quote_from_state(%{inside_quotes: inside_quotes}, feed_id, symbol) do
        inside_quotes
        |> Map.get([feed_id: feed_id, symbol: symbol] |> OrderBook.to_name)
      end

      defp call_handle_inside_quote(state, feed_id, symbol, snapshot) do
        [bid: inside_bid, ask: inside_ask] = current_inside_quote = state |> inside_quote_from_state(feed_id, symbol)

        handle_inside_quote(feed_id, symbol, inside_bid, inside_ask, snapshot, state)

        state
      end

      defp call_handle_inside_quote_if_changed(state, feed_id, symbol, changes, previous_inside_quote) do
        [bid: inside_bid, ask: inside_ask] = current_inside_quote = state |> inside_quote_from_state(feed_id, symbol)

        unless current_inside_quote == previous_inside_quote do
          handle_inside_quote(feed_id, symbol, inside_bid, inside_ask, changes, state)
        end

        state
      end

      defp changed_inside_quote?(%{bids: bids, asks: asks} = changes, previous_inside_quote) do
        (bids |> Enum.any? && bids |> changed_inside_bid?(previous_inside_quote)) || (asks |> Enum.any? && asks |> changed_inside_ask?(previous_inside_quote))
      end

      defp changed_inside_bid?(bids, nil), do: false
      defp changed_inside_bid?(bids, [bid: [price: prev_bid_price, size: prev_bid_size, processed_at: _pa, server_changed_at: _sca], ask: ask]) do
        bids
        |> Enum.any?(fn {price, {size, _processed_at, _server_changed_at}} ->
          price >= prev_bid_price || (price == prev_bid_price && size != prev_bid_size)
        end)
      end

      defp changed_inside_ask?(asks, nil), do: false
      defp changed_inside_ask?(asks, [bid: bid, ask: [price: prev_ask_price, size: prev_ask_size, processed_at: _pa, server_changed_at: _sca]]) do
        asks
        |> Enum.any?(fn {price, {size, _processed_at, _server_changed_at}} ->
          price <= prev_ask_price || (price == prev_ask_price && size != prev_ask_size)
        end)
      end
    end
  end
end
