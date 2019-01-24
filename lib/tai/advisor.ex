defmodule Tai.Advisor do
  @moduledoc """
  A behavior for implementing a server that receives order book changes.

  It can be used to monitor multiple quote streams and create, update or cancel orders.
  """

  @type advisor :: Tai.Advisor.t()
  @type store :: map
  @type product :: Tai.Venues.Product.t()
  @type order :: Tai.Trading.Order.t()
  @type t :: %Tai.Advisor{
          group_id: atom,
          advisor_id: atom,
          products: [product],
          inside_quotes: map,
          config: map,
          store: map
        }

  @callback handle_order_book_changes(
              order_book_feed_id :: atom,
              symbol :: atom,
              changes :: term,
              state :: advisor
            ) :: :ok

  @callback handle_inside_quote(
              order_book_feed_id :: atom,
              symbol :: atom,
              inside_quote :: Tai.Markets.Quote.t(),
              changes :: map | list,
              state :: advisor
            ) :: :ok | {:ok, store} | term

  @enforce_keys [
    :group_id,
    :advisor_id,
    :inside_quotes,
    :config,
    :store
  ]
  defstruct group_id: nil,
            advisor_id: nil,
            products: [],
            inside_quotes: %{},
            config: %{},
            store: %{}

  @spec to_name(atom, atom) :: atom
  def to_name(group_id, advisor_id) do
    :"advisor_#{group_id}_#{advisor_id}"
  end

  def cached_inside_quote(%Tai.Advisor{} = advisor, venue_id, product_symbol) do
    name = Tai.Markets.OrderBook.to_name(venue_id, product_symbol)
    Map.get(advisor.inside_quotes, name)
  end

  @spec cast_order_updated(atom, order | nil, order, fun) :: :ok
  def cast_order_updated(name, old_order, updated_order, callback) do
    GenServer.cast(name, {:order_updated, old_order, updated_order, callback})
  end

  defmacro __using__(_) do
    quote location: :keep do
      use GenServer
      require Logger

      @behaviour Tai.Advisor

      def start_link(
            group_id: group_id,
            advisor_id: advisor_id,
            products: products,
            config: config
          ) do
        name = Tai.Advisor.to_name(group_id, advisor_id)

        GenServer.start_link(
          __MODULE__,
          %Tai.Advisor{
            group_id: group_id,
            advisor_id: advisor_id,
            products: products,
            inside_quotes: %{},
            config: config,
            store: %{}
          },
          name: name
        )
      end

      @doc false
      def init(state) do
        Tai.MetaLogger.init_tid()
        {:ok, state, {:continue, :subscribe_to_products}}
      end

      @doc false
      def handle_continue(:subscribe_to_products, state) do
        state.products
        |> Enum.each(fn p ->
          Tai.PubSub.subscribe([
            {:order_book_snapshot, p.exchange_id, p.symbol},
            {:order_book_changes, p.exchange_id, p.symbol}
          ])
        end)

        {:noreply, state}
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
        handle_order_book_changes(feed_id, symbol, changes, state)

        previous_inside_quote = state |> Tai.Advisor.cached_inside_quote(feed_id, symbol)

        if inside_quote_is_stale?(previous_inside_quote, changes) do
          new_state =
            state
            |> cache_inside_quote(feed_id, symbol)
            |> execute_handle_inside_quote(
              feed_id,
              symbol,
              changes,
              previous_inside_quote
            )

          {:noreply, new_state}
        else
          {:noreply, state}
        end
      end

      @doc false
      def handle_cast({:order_updated, old_order, updated_order, callback}, state) do
        try do
          case callback.(old_order, updated_order, state) do
            {:ok, new_store} -> {:noreply, state |> Map.put(:store, new_store)}
            _ -> {:noreply, state}
          end
        rescue
          e ->
            Tai.Events.broadcast(%Tai.Events.AdvisorOrderUpdatedError{
              error: e,
              stacktrace: __STACKTRACE__
            })

            {:noreply, state}
        end
      end

      @doc false
      def handle_order_book_changes(order_book_feed_id, symbol, changes, state), do: :ok
      @doc false
      def handle_inside_quote(order_book_feed_id, symbol, inside_quote, changes, state), do: :ok

      defp cache_inside_quote(state, venue_id, product_symbol) do
        with {:ok, current_inside_quote} <-
               Tai.Markets.OrderBook.inside_quote(venue_id, product_symbol),
             key <- Tai.Markets.OrderBook.to_name(venue_id, product_symbol),
             old <- state.inside_quotes,
             updated <- Map.put(old, key, current_inside_quote) do
          Map.put(state, :inside_quotes, updated)
        end
      end

      defp inside_quote_is_stale?(
             previous_inside_quote,
             %Tai.Markets.OrderBook{bids: bids, asks: asks} = changes
           ) do
        (bids |> Enum.any?() && bids |> inside_bid_is_stale?(previous_inside_quote)) ||
          (asks |> Enum.any?() && asks |> inside_ask_is_stale?(previous_inside_quote))
      end

      defp inside_bid_is_stale?(_bids, nil), do: true

      defp inside_bid_is_stale?(bids, %Tai.Markets.Quote{} = prev_quote) do
        bids
        |> Enum.any?(fn {price, {size, _processed_at, _server_changed_at}} ->
          price >= prev_quote.bid.price ||
            (price == prev_quote.bid.price && size != prev_quote.bid.size)
        end)
      end

      defp inside_ask_is_stale?(asks, nil), do: true

      defp inside_ask_is_stale?(asks, %Tai.Markets.Quote{} = prev_quote) do
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
        current_inside_quote = Tai.Advisor.cached_inside_quote(state, order_book_feed_id, symbol)

        if current_inside_quote == previous_inside_quote do
          state
        else
          try do
            order_book_feed_id
            |> handle_inside_quote(symbol, current_inside_quote, changes, state)
            |> case do
              {:ok, new_store} ->
                Map.put(state, :store, new_store)

              :ok ->
                state

              unhandled ->
                Logger.warn(
                  "handle_inside_quote returned an invalid value: '#{inspect(unhandled)}'"
                )
            end
          rescue
            e ->
              Logger.warn(
                "handle_inside_quote raised an error: '#{inspect(e)}', stacktrace: #{
                  inspect(__STACKTRACE__)
                }"
              )
          end
        end
      end

      defoverridable handle_order_book_changes: 4,
                     handle_inside_quote: 5
    end
  end
end
