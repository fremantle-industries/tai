defmodule Tai.Advisor do
  @moduledoc """
  A behavior for implementing a server that receives order book changes.

  It can be used to monitor multiple quote streams and create, update or cancel orders.
  """

  alias Tai.{Advisor, PubSub, Trading.Order, MetaLogger}
  alias Tai.Markets.{OrderBook, Quote}

  @typedoc """
  The state of the running advisor
  """
  @type t :: Advisor

  @enforce_keys [:advisor_id, :exchanges, :order_books, :inside_quotes, :store]
  defstruct advisor_id: nil, exchanges: [], order_books: %{}, inside_quotes: %{}, store: %{}

  @doc """
  Callback when order book has bid or ask changes
  """
  @callback handle_order_book_changes(
              order_book_feed_id :: Atom.t(),
              symbol :: Atom.t(),
              changes :: term,
              state :: Advisor.t()
            ) :: :ok

  @doc """
  Callback when the highest bid or lowest ask changes price or size
  """
  @callback handle_inside_quote(
              order_book_feed_id :: Atom.t(),
              symbol :: Atom.t(),
              inside_quote :: Quote.t(),
              changes :: Map.t() | List.t(),
              state :: Advisor.t()
            ) :: :ok | {:ok, actions :: Map.t()}

  @doc """
  Callback when an order is enqueued
  """
  @callback handle_order_enqueued(order :: Order.t(), state :: Advisor.t()) :: :ok

  @doc """
  Callback when an order is created on the server
  """
  @callback handle_order_create_ok(order :: Order.t(), state :: Advisor.t()) :: :ok

  @doc """
  Callback when an order creation fails
  """
  @callback handle_order_create_error(reason :: term, order :: Order.t(), state :: Advisor.t()) ::
              :ok

  @doc """
  Callback when an order has been cancelled in the outbox but before the 
  request has been sent to the exchange.
  """
  @callback handle_order_cancelling(order :: Order.t(), state :: Advisor.t()) :: :ok

  @doc """
  Callback when an order has been cancelled on the exchange
  """
  @callback handle_order_cancelled(order :: Order.t(), state :: Advisor.t()) :: :ok

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

      def start_link(
            advisor_id: advisor_id,
            order_books: order_books,
            exchanges: exchanges,
            store: %{} = store
          ) do
        GenServer.start_link(
          __MODULE__,
          %Advisor{
            advisor_id: advisor_id,
            order_books: order_books,
            exchanges: exchanges,
            inside_quotes: %{},
            store: Map.merge(%{}, store)
          },
          name: advisor_id |> Advisor.to_name()
        )
      end

      @doc false
      def init(%Advisor{order_books: order_books, exchanges: exchanges} = state) do
        MetaLogger.init_pname()
        subscribe_to_order_book_channels(order_books)
        subscribe_to_exchange_channels(exchanges)

        {:ok, state}
      end

      @doc false
      def handle_info({:order_book_snapshot, order_book_feed_id, symbol, snapshot}, state) do
        new_state =
          state
          |> cache_inside_quote(order_book_feed_id, symbol)
          |> execute_handle_inside_quote(order_book_feed_id, symbol, snapshot)

        {:noreply, new_state}
      end

      @doc false
      def handle_info({:order_book_changes, order_book_feed_id, symbol, changes}, state) do
        new_state =
          Tai.TimeFrame.debug "handle_info({:order_book_changes...})" do
            handle_order_book_changes(order_book_feed_id, symbol, changes, state)

            previous_inside_quote = state |> cached_inside_quote(order_book_feed_id, symbol)

            if inside_quote_is_stale?(previous_inside_quote, changes) do
              state
              |> cache_inside_quote(order_book_feed_id, symbol)
              |> execute_handle_inside_quote(
                order_book_feed_id,
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

      @doc false
      def handle_info({:order_enqueued, order}, state) do
        handle_order_enqueued(order, state)

        {:noreply, state}
      end

      @doc false
      def handle_info({:order_create_ok, order}, state) do
        handle_order_create_ok(order, state)

        {:noreply, state}
      end

      @doc false
      def handle_info({:order_create_error, reason, order}, state) do
        handle_order_create_error(reason, order, state)

        {:noreply, state}
      end

      @doc false
      def handle_info({:order_cancelling, order}, state) do
        handle_order_cancelling(order, state)

        {:noreply, state}
      end

      @doc false
      def handle_info({:order_cancelled, order}, state) do
        handle_order_cancelled(order, state)

        {:noreply, state}
      end

      @doc """
      Returns the current state of the order book up to the given depth

      ## Examples

        iex> Tai.Advisor.quotes(feed_id: :test_feed_a, symbol: :btcusd, depth: 1)
        {:ok, %Tai.Markets.OrderBook{bids: [], asks: []}
      """
      def quotes(feed_id: order_book_feed_id, symbol: symbol, depth: depth) do
        [feed_id: order_book_feed_id, symbol: symbol]
        |> OrderBook.to_name()
        |> OrderBook.quotes(depth)
      end

      @doc """
      Returns the inside quote stored before the last 'handle_inside_quote' callback

      ## Examples

        iex> Tai.Advisor.cached_inside_quote(state, :test_feed_a, :btcusd)
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
      @doc false
      def handle_order_enqueued(order, state), do: :ok
      @doc false
      def handle_order_create_ok(order, state), do: :ok
      @doc false
      def handle_order_create_error(reason, order, state), do: :ok
      @doc false
      def handle_order_cancelling(order, state), do: :ok
      @doc false
      def handle_order_cancelled(order, state), do: :ok

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

      defp subscribe_to_exchange_channels(exchanges) do
        PubSub.subscribe(exchanges)
      end

      defp fetch_inside_quote(order_book_feed_id, symbol) do
        [feed_id: order_book_feed_id, symbol: symbol, depth: 1]
        |> quotes
        |> case do
          {:ok, %OrderBook{bids: bids, asks: asks}} ->
            %Quote{bid: bids |> List.first(), ask: asks |> List.first()}
        end
      end

      defp cache_inside_quote(state, order_book_feed_id, symbol) do
        current_inside_quote = fetch_inside_quote(order_book_feed_id, symbol)
        order_book_key = [feed_id: order_book_feed_id, symbol: symbol] |> OrderBook.to_name()
        new_inside_quotes = state.inside_quotes |> Map.put(order_book_key, current_inside_quote)

        state |> Map.put(:inside_quotes, new_inside_quotes)
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
          handle_inside_quote(order_book_feed_id, symbol, current_inside_quote, changes, state)
          |> normalize_handle_inside_quote_response
          |> case do
            {:ok, actions} ->
              actions
              |> cancel_orders
              |> submit_orders
              |> update_state(state)

            :error ->
              state
          end
        end
      end

      @empty_response {:ok, %{}}
      defp normalize_handle_inside_quote_response(:ok) do
        normalize_handle_inside_quote_response(@empty_response)
      end

      @default_actions %{cancel_orders: [], orders: []}
      defp normalize_handle_inside_quote_response({:ok, actions}) do
        {:ok, Map.merge(@default_actions, actions)}
      end

      defp normalize_handle_inside_quote_response(unhandled) do
        Logger.warn("handle_inside_quote returned an invalid value: '#{inspect(unhandled)}'")
        :error
      end

      defp cancel_orders(%{cancel_orders: cancel_orders} = actions) do
        OrderOutbox.cancel(cancel_orders)

        actions
      end

      defp submit_orders(%{orders: orders} = actions) do
        OrderOutbox.add(orders)

        actions
      end

      defp update_state(%{store: store}, state), do: state |> Map.put(:store, store)
      defp update_state(%{}, state), do: state

      defoverridable handle_order_book_changes: 4,
                     handle_inside_quote: 5,
                     handle_order_enqueued: 2,
                     handle_order_create_ok: 2,
                     handle_order_create_error: 3,
                     handle_order_cancelling: 2,
                     handle_order_cancelled: 2
    end
  end
end
