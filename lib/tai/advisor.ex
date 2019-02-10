defmodule Tai.Advisor do
  @moduledoc """
  A behavior for implementing a process that receives changes in the order book.

  It can be used to monitor one or more quote streams and create, update or cancel orders.
  """

  @type advisor :: Tai.Advisor.t()
  @type store :: map
  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type product :: Tai.Venues.Product.t()
  @type product_symbol :: Tai.Venues.Product.symbol()
  @type order :: Tai.Trading.Order.t()
  @type market_quote :: Tai.Markets.Quote.t()
  @type changes :: term
  @type t :: %Tai.Advisor{
          group_id: atom,
          advisor_id: atom,
          products: [product],
          config: map,
          store: map
        }

  @callback handle_inside_quote(venue_id, product_symbol, market_quote, changes, advisor) ::
              {:ok, store}

  @enforce_keys ~w(
    advisor_id
    config
    group_id
    products
    store
  )a
  defstruct ~w(
    advisor_id
    config
    group_id
    market_quotes
    products
    store
  )a

  @spec to_name(atom, atom) :: atom
  def to_name(group_id, advisor_id), do: :"advisor_#{group_id}_#{advisor_id}"

  @spec cast_order_updated(atom, order | nil, order, fun) :: :ok
  def cast_order_updated(name, old_order, updated_order, callback) do
    GenServer.cast(name, {:order_updated, old_order, updated_order, callback})
  end

  @spec cast_order_updated(atom, order | nil, order, fun, term) :: :ok
  def cast_order_updated(name, old_order, updated_order, callback, opts) do
    GenServer.cast(name, {:order_updated, old_order, updated_order, callback, opts})
  end

  defmacro __using__(_) do
    quote location: :keep do
      use GenServer

      @behaviour Tai.Advisor

      def start_link(
            group_id: group_id,
            advisor_id: advisor_id,
            products: products,
            config: config
          ) do
        name = Tai.Advisor.to_name(group_id, advisor_id)
        market_quotes = %Tai.Advisors.MarketQuotes{data: %{}}

        GenServer.start_link(
          __MODULE__,
          %Tai.Advisor{
            group_id: group_id,
            advisor_id: advisor_id,
            products: products,
            market_quotes: market_quotes,
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
      def handle_info({:order_book_snapshot, venue_id, product_symbol, snapshot}, state) do
        new_state =
          state
          |> cache_inside_quote(venue_id, product_symbol)
          |> execute_handle_inside_quote(venue_id, product_symbol, snapshot)

        {:noreply, new_state}
      end

      @doc false
      def handle_info({:order_book_changes, venue_id, product_symbol, changes}, state) do
        previous_inside_quote =
          state.market_quotes |> Tai.Advisors.MarketQuotes.for(venue_id, product_symbol)

        if inside_quote_is_stale?(previous_inside_quote, changes) do
          new_state =
            state
            |> cache_inside_quote(venue_id, product_symbol)
            |> execute_handle_inside_quote(
              venue_id,
              product_symbol,
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
      def handle_cast({:order_updated, old_order, updated_order, callback, opts}, state) do
        try do
          case callback.(old_order, updated_order, opts, state) do
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

      defp cache_inside_quote(state, venue_id, product_symbol) do
        {:ok, current_inside_quote} = Tai.Markets.OrderBook.inside_quote(venue_id, product_symbol)
        key = {venue_id, product_symbol}
        old_market_quotes = state.market_quotes
        updated_market_quotes_data = Map.put(old_market_quotes.data, key, current_inside_quote)
        updated_market_quotes = Map.put(old_market_quotes, :data, updated_market_quotes_data)

        state
        |> Map.put(:market_quotes, updated_market_quotes)
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
             venue_id,
             product_symbol,
             changes,
             previous_inside_quote \\ nil
           ) do
        current_inside_quote =
          state.market_quotes |> Tai.Advisors.MarketQuotes.for(venue_id, product_symbol)

        if current_inside_quote == previous_inside_quote do
          state
        else
          try do
            with {:ok, new_store} <-
                   handle_inside_quote(
                     venue_id,
                     product_symbol,
                     current_inside_quote,
                     changes,
                     state
                   ) do
              Map.put(state, :store, new_store)
            else
              unhandled ->
                Tai.Events.broadcast(%Tai.Events.AdvisorHandleInsideQuoteInvalidReturn{
                  advisor_id: state.advisor_id,
                  group_id: state.group_id,
                  venue_id: venue_id,
                  product_symbol: product_symbol,
                  return_value: unhandled
                })

                state
            end
          rescue
            e ->
              Tai.Events.broadcast(%Tai.Events.AdvisorHandleInsideQuoteError{
                advisor_id: state.advisor_id,
                group_id: state.group_id,
                venue_id: venue_id,
                product_symbol: product_symbol,
                error: e,
                stacktrace: __STACKTRACE__
              })
          end
        end
      end
    end
  end
end
