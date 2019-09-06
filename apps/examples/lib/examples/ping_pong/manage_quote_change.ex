defmodule Examples.PingPong.ManageQuoteChange do
  alias Examples.PingPong.CreateEntryOrder
  alias Tai.Markets.{PriceLevel, Quote}
  alias Tai.Trading.{Orders, Order}
  alias Tai.Advisor.State

  @type market_quote :: Tai.Markets.Quote.t()
  @type state :: Tai.Advisor.State.t()
  @type run_store :: Tai.Advisor.run_store()

  @spec with_all_quotes(market_quote) ::
          {:ok, market_quote} | {:error, :no_bid | :no_ask | :no_bid_or_ask}
  def with_all_quotes(%Quote{bid: %PriceLevel{}, ask: %PriceLevel{}} = market_quote),
    do: {:ok, market_quote}

  def with_all_quotes(%Quote{bid: nil, ask: %PriceLevel{}}), do: {:error, :no_bid}
  def with_all_quotes(%Quote{bid: %PriceLevel{}, ask: nil}), do: {:error, :no_ask}
  def with_all_quotes(%Quote{bid: nil, ask: nil}), do: {:error, :no_bid_or_ask}

  @spec manage_entry_order({:ok, market_quote}, state) :: {:ok, run_store}
  def manage_entry_order(
        {:ok, _},
        %State{store: %{entry_order: %Order{status: :open} = entry_order}} = state
      ) do
    {:ok, pending_cancel_order} = Orders.cancel(entry_order)
    new_run_store = Map.put(state.store, :entry_order, pending_cancel_order)
    {:ok, new_run_store}
  end

  def manage_entry_order(
        {:ok, _},
        %State{store: %{entry_order: %Order{}}} = state
      ) do
    {:ok, state.store}
  end

  def manage_entry_order({:ok, market_quote}, state) do
    advisor_id = Tai.Advisor.to_name(state.group_id, state.advisor_id)
    {:ok, entry_order} = CreateEntryOrder.create(advisor_id, market_quote, state.config)
    new_run_store = Map.put(state.store, :entry_order, entry_order)

    {:ok, new_run_store}
  end

  def manage_entry_order({:error, _}, state), do: {:ok, state.store}
end
