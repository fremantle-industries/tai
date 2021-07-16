defmodule Examples.PingPong.ManageQuoteChange do
  alias Examples.PingPong.{CreateEntryOrder, EntryPrice}
  alias Tai.Orders.Order
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

  @spec manage_entry_order({:ok, market_quote}, state) :: {:ok, run_store}
  def manage_entry_order(_, _)

  def manage_entry_order(
        {:ok, _},
        %State{store: %{entry_order: %Order{status: :open} = entry_order}} = state
      ) do
    {:ok, market_quote} =
      Tai.Advisors.MarketQuotes.for(
        state.market_quotes,
        entry_order.venue |> String.to_atom(),
        entry_order.product_symbol |> String.to_atom()
      )

    entry_price = EntryPrice.calculate(market_quote, state.config.product)

    if Decimal.compare(entry_order.price, entry_price) == :eq do
      {:ok, state.store}
    else
      {:ok, pending_cancel_order} = Tai.Orders.cancel(entry_order)
      new_run_store = Map.put(state.store, :entry_order, pending_cancel_order)
      {:ok, new_run_store}
    end
  end

  def manage_entry_order(
        {:ok, _},
        %State{store: %{entry_order: %Order{}}} = state
      ) do
    {:ok, state.store}
  end

  def manage_entry_order({:ok, market_quote}, state) do
    advisor_id = Tai.Advisor.process_name(state.group_id, state.advisor_id)

    {:ok, entry_order} = CreateEntryOrder.create(advisor_id, market_quote, state.config)

    new_run_store = Map.put(state.store, :entry_order, entry_order)

    {:ok, new_run_store}
  end

  def manage_entry_order({:error, _}, state) do
    {:ok, state.store}
  end
end
