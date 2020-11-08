defmodule Examples.PingPong.ManageQuoteChange do
  alias Examples.PingPong.{CreateEntryOrder, EntryPrice}
  alias Tai.Trading.{Orders, Order}
  alias Tai.Markets.Quote
  alias Tai.Advisor.State

  @type market_quote :: Tai.Markets.Quote.t()
  @type state :: Tai.Advisor.State.t()
  @type run_store :: Tai.Advisor.run_store()

  @spec with_all_quotes(market_quote) ::
          {:ok, market_quote} | {:error, :no_bid | :no_ask | :no_bid_or_ask}
  def with_all_quotes(%Quote{bids: [_ | _], asks: [_ | _]} = market_quote),
    do: {:ok, market_quote}

  def with_all_quotes(%Quote{bids: [], asks: []}), do: {:error, :no_bid_or_ask}
  def with_all_quotes(%Quote{bids: [], asks: _}), do: {:error, :no_bid}
  def with_all_quotes(%Quote{bids: _, asks: []}), do: {:error, :no_ask}

  @spec manage_entry_order({:ok, market_quote}, state, module) :: {:ok, run_store}
  def manage_entry_order(_, _, orders_provider \\ Orders)

  def manage_entry_order(
        {:ok, _},
        %State{store: %{entry_order: %Order{status: :open} = entry_order}} = state,
        orders_provider
      ) do
    {:ok, market_quote} =
      Tai.Advisors.MarketQuotes.for(
        state.market_quotes,
        entry_order.venue_id,
        entry_order.product_symbol
      )

    entry_price = EntryPrice.calculate(market_quote, state.config.product)

    if Decimal.compare(entry_order.price, entry_price) == :eq do
      {:ok, state.store}
    else
      {:ok, pending_cancel_order} = orders_provider.cancel(entry_order)
      new_run_store = Map.put(state.store, :entry_order, pending_cancel_order)
      {:ok, new_run_store}
    end
  end

  def manage_entry_order(
        {:ok, _},
        %State{store: %{entry_order: %Order{}}} = state,
        _orders_provider
      ) do
    {:ok, state.store}
  end

  def manage_entry_order({:ok, market_quote}, state, orders_provider) do
    advisor_id = Tai.Advisor.process_name(state.group_id, state.advisor_id)

    {:ok, entry_order} =
      CreateEntryOrder.create(advisor_id, market_quote, state.config, orders_provider)

    new_run_store = Map.put(state.store, :entry_order, entry_order)

    {:ok, new_run_store}
  end

  def manage_entry_order({:error, _}, state, _), do: {:ok, state.store}
end
