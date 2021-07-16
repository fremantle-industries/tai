defmodule Examples.PingPong.ManageOrderUpdate do
  alias Tai.{Advisor, Advisors}
  alias Examples.PingPong

  @type order :: Tai.Orders.Order.t()
  @type run_store :: Advisor.run_store()
  @type state :: Advisor.State.t()

  @spec entry_order_updated(run_store, prev :: order, state) :: {:ok, run_store}
  def entry_order_updated(run_store, prev, state)

  def entry_order_updated(
        %{entry_order: %Tai.Orders.Order{status: :canceled} = entry_order} = run_store,
        _prev,
        state
      ) do
    new_run_store = recreate_entry_order(entry_order, run_store, state)
    {:ok, new_run_store}
  end

  def entry_order_updated(
        %{entry_order: %Tai.Orders.Order{status: :filled} = entry_order} = run_store,
        prev,
        state
      ) do
    new_run_store = create_exit_order(entry_order, prev, run_store, state)
    {:ok, new_run_store}
  end

  def entry_order_updated(run_store, _, _) do
    {:ok, run_store}
  end

  defp advisor_process(state) do
    Advisor.process_name(state.group_id, state.advisor_id)
  end

  defp recreate_entry_order(entry_order, run_store, state) do
    venue = entry_order.venue |> String.to_atom()
    product_symbol = entry_order.product_symbol |> String.to_atom()
    {:ok, market_quote} = Advisors.MarketQuotes.for(state.market_quotes, venue, product_symbol)

    {:ok, entry_order} =
      state
      |> advisor_process()
      |> PingPong.CreateEntryOrder.create(market_quote, state.config)

    Map.put(run_store, :entry_order, entry_order)
  end

  defp create_exit_order(entry_order, prev, run_store, state) do
    {:ok, exit_order} =
      state
      |> advisor_process()
      |> PingPong.CreateExitOrder.create(prev, entry_order, state.config)

    Map.put(run_store, :exit_order, exit_order)
  end
end
