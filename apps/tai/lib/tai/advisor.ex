defmodule Tai.Advisor do
  @moduledoc """
  A behavior for implementing a server that receives events such as market quotes.

  It can be used to receive one or more quote streams to record data and create, update or cancel orders.
  """

  defmodule State do
    @type fleet_id :: Tai.Fleets.FleetConfig.id()
    @type advisor_id :: Tai.Fleets.AdvisorConfig.advisor_id()
    @type config :: struct | map
    @type run_store :: map
    @type t :: %State{
            fleet_id: fleet_id,
            advisor_id: advisor_id,
            config: config,
            store: run_store
          }

    @enforce_keys ~w[advisor_id config fleet_id store]a
    defstruct ~w[advisor_id config fleet_id store market_quotes]a
  end

  alias Tai.Markets.Quote

  @type fleet_id :: Tai.Fleets.FleetConfig.id()
  @type advisor_id :: Tai.Fleets.AdvisorConfig.advisor_id()
  @type advisor_name :: atom
  @type market_quote :: Tai.Markets.Quote.t()
  @type run_store :: State.run_store()
  @type state :: State.t()
  @type terminate_reason :: :normal | :shutdown | {:shutdown, term} | term

  @callback after_start(state) :: {:ok, run_store}
  @callback on_terminate(terminate_reason, state) :: term
  @callback handle_market_quote(market_quote, state) :: {:ok, run_store}

  @spec process_name(fleet_id, advisor_id) :: advisor_name
  def process_name(fleet_id, advisor_id), do: :"advisor_#{fleet_id}_#{advisor_id}"

  defmacro __using__(_) do
    quote location: :keep do
      use GenServer

      @behaviour Tai.Advisor

      def start_link(advisor_id: advisor_id, fleet_id: fleet_id, quote_keys: quote_keys, config: config, store: store) do
        name = Tai.Advisor.process_name(fleet_id, advisor_id)
        market_quotes = %Tai.Advisors.MarketQuotes{data: %{}}

        state = %State{
          advisor_id: advisor_id,
          fleet_id: fleet_id,
          config: config,
          store: store,
          market_quotes: market_quotes
        }

        GenServer.start_link(__MODULE__, {state, quote_keys}, name: name)
      end

      @impl true
      def init({state, quote_keys}) do
        Process.flag(:trap_exit, true)
        {:ok, state, {:continue, {:subscribe, quote_keys}}}
      end

      @impl true
      def terminate(reason, state) do
        on_terminate(reason, state)
      end

      @impl true
      def handle_info({:market_quote_store, :after_put, %Quote{} = market_quote}, state) do
        key = {market_quote.venue_id, market_quote.product_symbol}
        new_data = Map.put(state.market_quotes.data, key, market_quote)
        new_market_quotes = Map.put(state.market_quotes, :data, new_data)
        new_state = Map.put(state, :market_quotes, new_market_quotes)

        {
          :noreply,
          new_state,
          {:continue, {:handle_market_quote, market_quote}}
        }
      end

      @impl true
      def handle_continue({:subscribe, quote_keys}, state) do
        quote_keys |> Enum.each(&Tai.SystemBus.subscribe({:market_quote_store, &1}))
        {:noreply, state, {:continue, :after_start}}
      end

      @impl true
      def handle_continue(:after_start, state) do
        {:ok, new_run_store} = after_start(state)
        new_state = Map.put(state, :store, new_run_store)
        {:noreply, new_state}
      end

      @impl true
      def handle_continue({:handle_market_quote, market_quote}, state) do
        new_state =
          try do
            with {:ok, new_store} <- handle_market_quote(market_quote, state) do
              %{state | store: new_store}
            else
              unhandled ->
                %Tai.Events.AdvisorHandleMarketQuoteInvalidReturn{
                  advisor_id: state.advisor_id,
                  fleet_id: state.fleet_id,
                  event: market_quote,
                  return_value: unhandled
                }
                |> TaiEvents.warning()

                state
            end
          rescue
            e ->
              %Tai.Events.AdvisorHandleMarketQuoteError{
                advisor_id: state.advisor_id,
                fleet_id: state.fleet_id,
                event: market_quote,
                error: e,
                stacktrace: __STACKTRACE__
              }
              |> TaiEvents.warning()

              state
          end

        {:noreply, new_state}
      end

      @impl true
      def after_start(state), do: {:ok, state.store}

      @impl true
      def on_terminate(_, _), do: :ok

      @impl true
      def handle_market_quote(_, state), do: {:ok, state.store}

      defoverridable after_start: 1, on_terminate: 2, handle_market_quote: 2
    end
  end
end
