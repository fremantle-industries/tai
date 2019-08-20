defmodule Tai.Advisor do
  @moduledoc """
  A behavior for implementing a process that receives changes in the order book.

  It can be used to monitor one or more quote streams and create, update or cancel orders.
  """

  defmodule State do
    @type group_id :: Tai.AdvisorGroup.id()
    @type id :: atom
    @type product :: Tai.Venues.Product.t()
    @type config :: struct | map
    @type run_store :: map
    @type t :: %State{
            group_id: group_id,
            advisor_id: id,
            products: [product],
            config: config,
            store: run_store,
            trades: list
          }

    @enforce_keys ~w(advisor_id config group_id products store trades)a
    defstruct ~w(advisor_id config group_id market_quotes products store trades)a
  end

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type product_symbol :: Tai.Venues.Product.symbol()
  @type order :: Tai.Trading.Order.t()
  @type group_id :: Tai.AdvisorGroup.id()
  @type id :: State.id()
  @type run_store :: State.run_store()
  @type state :: State.t()

  @callback handle_inside_quote(venue_id, product_symbol, map, state) ::
              {:ok, run_store}

  @spec to_name(group_id, id) :: atom
  def to_name(group_id, advisor_id), do: :"advisor_#{group_id}_#{advisor_id}"

  @spec cast_order_updated(atom, order | nil, order, fun) :: :ok
  def cast_order_updated(name, old_order, updated_order, callback) do
    GenServer.cast(name, {:order_updated, old_order, updated_order, callback})
  end

  @spec cast_order_updated(atom, order | nil, order, fun, term) :: :ok
  def cast_order_updated(name, old_order, updated_order, callback, opts) do
    GenServer.cast(name, {:order_updated, old_order, updated_order, callback, opts})
  end

  defmacro __using__(opts \\ []) do
    subscribe_to =
      Keyword.get(opts, :subscribe_to, [
        Tai.AdvisorResponders.Changes,
        Tai.AdvisorResponders.MarketQuote
      ])

    quote location: :keep do
      use GenServer

      @behaviour Tai.Advisor
      @subscribe_to unquote(subscribe_to)

      def start_link(
            group_id: group_id,
            advisor_id: advisor_id,
            products: products,
            config: config,
            store: store,
            trades: trades
          ) do
        name = Tai.Advisor.to_name(group_id, advisor_id)
        market_quotes = %Tai.Advisors.MarketQuotes{data: %{}}
        config = Map.put(config || %{}, :subscribe_to, @subscribe_to)

        state = %State{
          group_id: group_id,
          advisor_id: advisor_id,
          products: products,
          market_quotes: market_quotes,
          config: config,
          store: store,
          trades: trades
        }

        GenServer.start_link(__MODULE__, state, name: name)
      end

      @doc false
      def init(state) do
        {:ok, state, {:continue, :subscribe_to_products}}
      end

      defoverridable init: 1

      @doc false
      def handle_continue(:subscribe_to_products, state) do
        state.products
        |> Enum.each(fn p ->
          Tai.PubSub.subscribe([
            {:order_book_snapshot, p.venue_id, p.symbol},
            {:order_book_changes, p.venue_id, p.symbol}
          ])
        end)

        {:noreply, state}
      end

      @doc false
      def handle_info({action, venue_id, product_symbol, changes}, state) do
        state
        |> Map.get(:config)
        |> Map.get(:subscribe_to)
        |> Enum.reduce({%{}, state}, fn mod, acc ->
          args = {action, venue_id, product_symbol, changes}
          {:ok, returns} = apply(mod, :respond, [acc, args])
          returns
        end)
        |> execute_handle_inside_quote(venue_id, product_symbol)
        |> (&{:noreply, &1}).()
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
            Tai.Events.info(%Tai.Events.AdvisorOrderUpdatedError{
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
            Tai.Events.info(%Tai.Events.AdvisorOrderUpdatedError{
              error: e,
              stacktrace: __STACKTRACE__
            })

            {:noreply, state}
        end
      end

      defp execute_handle_inside_quote(
             {data, state},
             venue_id,
             product_symbol
           ) do
        try do
          with {:ok, new_store} <- handle_inside_quote(venue_id, product_symbol, data, state) do
            Map.put(state, :store, new_store)
          else
            unhandled ->
              Tai.Events.info(%Tai.Events.AdvisorHandleInsideQuoteInvalidReturn{
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
            Tai.Events.info(%Tai.Events.AdvisorHandleInsideQuoteError{
              advisor_id: state.advisor_id,
              group_id: state.group_id,
              venue_id: venue_id,
              product_symbol: product_symbol,
              error: e,
              stacktrace: __STACKTRACE__
            })

            state
        end
      end
    end
  end
end
