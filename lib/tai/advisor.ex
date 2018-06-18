defmodule Tai.Advisor do
  @moduledoc """
  A behavior for implementing a server that receives order book changes.

  It can be used to monitor multiple quote streams and create, update or cancel orders.
  """

  alias Tai.{PubSub, MetaLogger}
  alias Tai.Markets.{OrderBook, Quote}

  @typedoc """
  The state of the running advisor
  """
  @type t :: Tai.Advisor

  @enforce_keys [:advisor_id, :accounts, :order_books, :inside_quotes, :store]
  defstruct advisor_id: nil, accounts: [], order_books: %{}, inside_quotes: %{}, store: %{}

  @doc """
  Callback when order book has bid or ask changes
  """
  @callback handle_order_book_changes(
              order_book_feed_id :: atom,
              symbol :: atom,
              changes :: term,
              state :: Tai.Advisor.t()
            ) :: :ok

  @doc """
  Callback when the highest bid or lowest ask changes price or size
  """
  @callback handle_inside_quote(
              order_book_feed_id :: atom,
              symbol :: atom,
              inside_quote :: Tai.Markets.Quote.t(),
              changes :: map | list,
              state :: Tai.Advisor.t()
            ) :: :ok | {:ok, actions :: map}

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

      alias Tai.Markets.OrderBook

      @behaviour Tai.Advisor

      def start_link(
            advisor_id: advisor_id,
            order_books: order_books,
            accounts: accounts,
            store: %{} = store
          ) do
        GenServer.start_link(
          __MODULE__,
          %Tai.Advisor{
            advisor_id: advisor_id,
            order_books: order_books,
            accounts: accounts,
            inside_quotes: %{},
            store: Map.merge(%{}, store)
          },
          name: advisor_id |> Tai.Advisor.to_name()
        )
      end

      @doc false
      def init(%Tai.Advisor{order_books: order_books, accounts: accounts} = state) do
        MetaLogger.init_tid()
        subscribe_to_order_book_channels(order_books)
        subscribe_to_account_channels(accounts)

        {:ok, state}
      end

      @doc false
      def handle_info({:order_book_snapshot, feed_id, symbol, snapshot}, state) do
        new_state =
          state
          |> cache_inside_quote(feed_id, symbol)
          |> execute_handle_inside_quote(feed_id, symbol, snapshot)

        {:noreply, new_state}
      end

      @doc false
      def handle_info({:order_book_changes, feed_id, symbol, changes}, state) do
        new_state =
          Tai.TimeFrame.debug "handle_info({:order_book_changes...})" do
            handle_order_book_changes(feed_id, symbol, changes, state)

            previous_inside_quote = state |> cached_inside_quote(feed_id, symbol)

            if inside_quote_is_stale?(previous_inside_quote, changes) do
              state
              |> cache_inside_quote(feed_id, symbol)
              |> execute_handle_inside_quote(
                feed_id,
                symbol,
                changes,
                previous_inside_quote
              )
            else
              state
            end
          end

        {:noreply, new_state}
      end

      @doc """
      Returns the current state of the order book up to the given depth

      ## Examples

        iex> Tai.Advisor.quotes(feed_id: :test_feed_a, symbol: :btc_usd, depth: 1)
        {:ok, %Tai.Markets.OrderBook{bids: [], asks: []}
      """
      def quotes(feed_id: feed_id, symbol: symbol, depth: depth) do
        [feed_id: feed_id, symbol: symbol]
        |> OrderBook.to_name()
        |> OrderBook.quotes(depth)
      end

      @doc """
      Returns the inside quote stored before the last 'handle_inside_quote' callback

      ## Examples

        iex> Tai.Advisor.cached_inside_quote(state, :test_feed_a, :btc_usd)
        %Tai.Markets.Quote{
          bid: %Tai.Markets.PriceLevel{price: 101.1, size: 1.1, processed_at: nil, server_changed_at: nil},
          ask: %Tai.Markets.PriceLevel{price: 101.2, size: 0.1, processed_at: nil, server_changed_at: nil}
        }
      """
      def cached_inside_quote(%{inside_quotes: inside_quotes}, order_book_feed_id, symbol) do
        inside_quotes
        |> Map.get([feed_id: order_book_feed_id, symbol: symbol] |> OrderBook.to_name())
      end

      @doc false
      def handle_order_book_changes(order_book_feed_id, symbol, changes, state), do: :ok
      @doc false
      def handle_inside_quote(order_book_feed_id, symbol, inside_quote, changes, state), do: :ok

      defp subscribe_to_order_book_channels(order_books) do
        order_books
        |> Enum.each(fn {order_book_feed_id, symbols} ->
          symbols
          |> Enum.each(fn symbol ->
            PubSub.subscribe([
              {:order_book_snapshot, order_book_feed_id, symbol},
              {:order_book_changes, order_book_feed_id, symbol}
            ])
          end)
        end)
      end

      defp subscribe_to_account_channels(accounts) do
        PubSub.subscribe(accounts)
      end

      defp cache_inside_quote(state, feed_id, symbol) do
        with {:ok, current_inside_quote} <- OrderBook.inside_quote(feed_id, symbol),
             feed_and_symbol <- [feed_id: feed_id, symbol: symbol],
             key <- OrderBook.to_name(feed_and_symbol),
             old <- state.inside_quotes,
             updated <- Map.put(old, key, current_inside_quote) do
          Map.put(state, :inside_quotes, updated)
        end
      end

      defp inside_quote_is_stale?(
             previous_inside_quote,
             %OrderBook{bids: bids, asks: asks} = changes
           ) do
        (bids |> Enum.any?() && bids |> inside_bid_is_stale?(previous_inside_quote)) ||
          (asks |> Enum.any?() && asks |> inside_ask_is_stale?(previous_inside_quote))
      end

      defp inside_bid_is_stale?(_bids, nil), do: false

      defp inside_bid_is_stale?(bids, %Quote{} = prev_quote) do
        bids
        |> Enum.any?(fn {price, {size, _processed_at, _server_changed_at}} ->
          price >= prev_quote.bid.price ||
            (price == prev_quote.bid.price && size != prev_quote.bid.size)
        end)
      end

      defp inside_ask_is_stale?(asks, nil), do: false

      defp inside_ask_is_stale?(asks, %Quote{} = prev_quote) do
        asks
        |> Enum.any?(fn {price, {size, _processed_at, _server_changed_at}} ->
          price <= prev_quote.ask.price ||
            (price == prev_quote.ask.price && size != prev_quote.ask.size)
        end)
      end

      defp execute_handle_inside_quote(
             state,
             order_book_feed_id,
             symbol,
             changes,
             previous_inside_quote \\ nil
           ) do
        current_inside_quote = cached_inside_quote(state, order_book_feed_id, symbol)

        if current_inside_quote == previous_inside_quote do
          state
        else
          order_book_feed_id
          |> handle_inside_quote(symbol, current_inside_quote, changes, state)
          |> normalize_handle_inside_quote_response
          |> case do
            {:ok, actions} -> update_state(actions, state)
            :error -> state
          end
        end
      end

      @empty_response {:ok, %{}}
      defp normalize_handle_inside_quote_response(:ok) do
        normalize_handle_inside_quote_response(@empty_response)
      end

      defp normalize_handle_inside_quote_response({:ok, _actions} = response), do: response

      defp normalize_handle_inside_quote_response(unhandled) do
        Logger.warn("handle_inside_quote returned an invalid value: '#{inspect(unhandled)}'")
        :error
      end

      defp update_state(%{store: store}, state), do: state |> Map.put(:store, store)
      defp update_state(%{}, state), do: state

      defoverridable handle_order_book_changes: 4,
                     handle_inside_quote: 5
    end
  end
end
