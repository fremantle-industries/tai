defmodule Examples.PingPong.ManageOrderUpdate do
  alias Examples.PingPong.{CreateEntryOrder, CreateExitOrder}
  alias Tai.Trading.Order

  @type state :: Tai.Advisor.State.t()
  @type run_store :: Tai.Advisor.run_store()

  @spec entry_order_updated(run_store, state) :: {:ok, run_store}
  def entry_order_updated(
        %{entry_order: %Order{status: :canceled} = entry_order} = run_store,
        state
      ) do
    advisor_id = Tai.Advisor.to_name(state.group_id, state.advisor_id)

    market_quote =
      Tai.Advisors.MarketQuotes.for(
        state.market_quotes,
        entry_order.venue_id,
        entry_order.product_symbol
      )

    {:ok, entry_order} = CreateEntryOrder.create(advisor_id, market_quote, state.config)
    new_run_store = Map.put(run_store, :entry_order, entry_order)

    {:ok, new_run_store}
  end

  def entry_order_updated(
        %{entry_order: %Order{status: :filled} = entry_order} = run_store,
        state
      ) do
    advisor_id = Tai.Advisor.to_name(state.group_id, state.advisor_id)
    {:ok, exit_order} = CreateExitOrder.create(advisor_id, entry_order, state.config)
    new_run_store = Map.put(run_store, :exit_order, exit_order)

    {:ok, new_run_store}
  end

  def entry_order_updated(run_store, _), do: {:ok, run_store}
end
