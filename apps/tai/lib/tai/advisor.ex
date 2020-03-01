defmodule Tai.Advisor do
  @moduledoc """
  A behavior for implementing a server that receives events such as market quotes.

  It can be used to receive one or more quote streams to record data and create, update or cancel orders.
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

  alias Tai.Markets.Quote

  @type group_id :: Tai.AdvisorGroup.id()
  @type id :: State.id()
  @type advisor_name :: atom
  @type event :: term
  @type run_store :: State.run_store()
  @type state :: State.t()

  @callback after_start(state) :: {:ok, run_store}
  @callback handle_event(event, state) :: {:ok, run_store}

  @spec to_name(group_id, id) :: advisor_name
  def to_name(group_id, advisor_id), do: :"advisor_#{group_id}_#{advisor_id}"

  defmacro __using__(_) do
    quote location: :keep do
      use GenServer

      @behaviour Tai.Advisor

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

      def init(state), do: {:ok, state, {:continue, :started}}

      def handle_info({:market_quote_store, :after_put, %Quote{} = event}, state) do
        key = {event.venue_id, event.product_symbol}
        new_data = Map.put(state.market_quotes.data, key, event)
        new_market_quotes = Map.put(state.market_quotes, :data, new_data)
        new_state = Map.put(state, :market_quotes, new_market_quotes)

        {
          :noreply,
          new_state,
          {:continue, {:execute_event, event}}
        }
      end

      def handle_continue(:started, state) do
        {:ok, new_run_store} = after_start(state)
        new_state = Map.put(state, :store, new_run_store)

        state.products
        |> Enum.each(&Tai.SystemBus.subscribe({:market_quote_store, {&1.venue_id, &1.symbol}}))

        {:noreply, new_state}
      end

      def handle_continue({:execute_event, event}, state) do
        new_state =
          try do
            with {:ok, new_store} <- handle_event(event, state) do
              Map.put(state, :store, new_store)
            else
              unhandled ->
                %Tai.Events.AdvisorHandleEventInvalidReturn{
                  advisor_id: state.advisor_id,
                  group_id: state.group_id,
                  event: event,
                  return_value: unhandled
                }
                |> TaiEvents.warn()

                state
            end
          rescue
            e ->
              %Tai.Events.AdvisorHandleEventError{
                advisor_id: state.advisor_id,
                group_id: state.group_id,
                event: event,
                error: e,
                stacktrace: __STACKTRACE__
              }
              |> TaiEvents.warn()

              state
          end

        {:noreply, new_state}
      end

      def after_start(state), do: {:ok, state.store}

      def handle_event(_, state), do: {:ok, state.store}

      defoverridable after_start: 1, handle_event: 2
    end
  end
end
