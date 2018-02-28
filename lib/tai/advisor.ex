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

      alias Tai.{Advisor, Markets.OrderBook}

      @behaviour Advisor

      def start_link(advisor_id: advisor_id, order_book_feed_ids: order_book_feed_ids) do
        GenServer.start_link(
          __MODULE__,
          %{advisor_id: advisor_id, order_book_feed_ids: order_book_feed_ids},
          name: advisor_id |> Advisor.to_name
        )
      end

      @doc false
      def init(%{order_book_feed_ids: order_book_feed_ids} = state) do
        order_book_feed_ids
        |> subscribe_to_order_book_channels

        {:ok, state}
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

      @doc false
      def handle_info({:order_book_changes, feed_id, symbol, changes}, state) do
        handle_order_book_changes(feed_id, symbol, changes, state)
        check_inside_quote(feed_id, symbol, changes, state)

        {:noreply, state}
      end
      @doc false
      def handle_info({:order_book_snapshot, feed_id, symbol, normalized_bids, normalized_asks}, state) do
        inside_quote(feed_id, symbol)
        |> handle_snapshot_inside_quote(feed_id, symbol, %{bids: normalized_bids, asks: normalized_asks}, state)

        {:noreply, state}
      end

      defp handle_snapshot_inside_quote(
        {:ok, [bid: inside_bid, ask: inside_ask]},
        feed_id,
        symbol,
        snapshot,
        state
      ) do
        handle_inside_quote(feed_id, symbol, inside_bid, inside_ask, snapshot, state)
      end

      defp inside_quote(feed_id, symbol) do
        [feed_id: feed_id, symbol: symbol, depth: 1]
        |> quotes
        |> case do
          {:ok, %{bids: bids, asks: asks}} ->
            {:ok, [bid: bids |> List.first, ask: asks |> List.first]}
        end
      end

      defp subscribe_to_order_book_channels([]), do: nil
      defp subscribe_to_order_book_channels([feed_id | tail]) do
        PubSub.subscribe({:order_book_changes, feed_id})
        PubSub.subscribe({:order_book_snapshot, feed_id})

        tail
        |> subscribe_to_order_book_channels
      end

      defp check_inside_quote(feed_id, symbol, changes, state) do
        [feed_id: feed_id, symbol: symbol, depth: 1]
        |> quotes
        |> case do
          {:ok, %{bids: bids, asks: asks}} ->
            inside_bid = bids |> List.first
            inside_ask = asks |> List.first

            changes
            |> to_quotes
            |> contains_inside_quote?(inside_bid, inside_ask)
            |> call_handle_inside_quote(feed_id, symbol, inside_bid, inside_ask, changes, state)
        end
      end

      defp to_quotes(changes) do
        changes
        |> Enum.reduce(
          %{bids: [], asks: []},
          fn [side: side, price: price, size: size], acc ->
            case side do
              :bid -> Map.put(acc, :bids, [[price: price, size: size] | acc[:bids]])
              :ask -> Map.put(acc, :asks, [[price: price, size: size] | acc[:asks]])
            end
          end
        )
      end

      defp contains_inside_quote?(%{bids: change_bids, asks: change_asks} = quote_changes, inside_bid, inside_ask) do
        {false, quote_changes}
        |> contains_inside?(:bids, inside_bid)
        |> contains_inside?(:asks, inside_ask)
        |> deleted_prior_inside?(:bids, inside_bid)
        |> deleted_prior_inside?(:asks, inside_ask)
      end
      defp contains_inside?({false, quote_changes}, side, inside) do
        {
          quote_changes[side] |> Enum.member?(inside),
          quote_changes
        }
      end
      defp contains_inside?({true, quote_changes}, _side, _inside), do: {true, quote_changes}
      defp deleted_prior_inside?({false, quote_changes}, _side, nil), do: {false, quote_changes}
      defp deleted_prior_inside?({false, %{bids: bids} = quote_changes}, :bids, [price: inside_price, size: _]) do
        has_higher_deletion_bids = bids
                                  |> Enum.filter(fn([price: price, size: size]) -> size == 0 && price > inside_price end)
                                  |> Enum.any?

        {has_higher_deletion_bids, quote_changes}
      end
      defp deleted_prior_inside?({false, %{asks: asks} = quote_changes}, :asks, [price: inside_price, size: _]) do
        has_lower_deletion_asks = asks
                                  |> Enum.filter(fn([price: price, size: size]) -> size == 0 && price < inside_price end)
                                  |> Enum.any?

        {has_lower_deletion_asks, quote_changes}
      end
      defp deleted_prior_inside?({true, quote_changes}, _side, _inside), do: {true, quote_changes}

      defp call_handle_inside_quote({false, _}, _feed_id, _symbol, _bid, _ask, _changes, _state), do: nil
      defp call_handle_inside_quote({true, _}, feed_id, symbol, bid, ask, changes, state) do
        handle_inside_quote(feed_id, symbol, bid, ask, changes, state)
      end
    end
  end
end
