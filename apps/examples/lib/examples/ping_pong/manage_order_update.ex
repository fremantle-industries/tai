defmodule Examples.PingPong.ManageOrderUpdate do
  alias Tai.Orders.Order

  defmodule DefaultOrderProvider do
    alias Examples.PingPong.{CreateEntryOrder, CreateExitOrder}

    defdelegate create_entry_order(advisor_id, market_quote, config),
      to: CreateEntryOrder,
      as: :create

    defdelegate create_exit_order(advisor_id, prev_entry_order, entry_order, config),
      to: CreateExitOrder,
      as: :create
  end

  @type order :: Order.t()
  @type run_store :: Tai.Advisor.run_store()
  @type state :: Tai.Advisor.State.t()

  @spec entry_order_updated(run_store, prev :: order, state, module) :: {:ok, run_store}
  def entry_order_updated(run_store, prev, state, order_provider \\ DefaultOrderProvider)

  def entry_order_updated(
        %{entry_order: %Order{status: :canceled} = entry_order} = run_store,
        _prev,
        state,
        order_provider
      ) do
    advisor_process = Tai.Advisor.process_name(state.group_id, state.advisor_id)

    {:ok, market_quote} =
      Tai.Advisors.MarketQuotes.for(
        state.market_quotes,
        entry_order.venue_id,
        entry_order.product_symbol
      )

    {:ok, entry_order} =
      order_provider.create_entry_order(advisor_process, market_quote, state.config)

    new_run_store = Map.put(run_store, :entry_order, entry_order)

    {:ok, new_run_store}
  end

  def entry_order_updated(
        %{entry_order: %Order{status: :partially_filled} = entry_order} = run_store,
        prev,
        state,
        order_provider
      ) do
    advisor_process = Tai.Advisor.process_name(state.group_id, state.advisor_id)

    {:ok, exit_order} =
      order_provider.create_exit_order(advisor_process, prev, entry_order, state.config)

    new_run_store = Map.put(run_store, :exit_order, exit_order)

    {:ok, new_run_store}
  end

  def entry_order_updated(
        %{entry_order: %Order{status: :filled} = entry_order} = run_store,
        prev,
        state,
        order_provider
      ) do
    advisor_process = Tai.Advisor.process_name(state.group_id, state.advisor_id)

    {:ok, exit_order} =
      order_provider.create_exit_order(advisor_process, prev, entry_order, state.config)

    new_run_store = Map.put(run_store, :exit_order, exit_order)

    {:ok, new_run_store}
  end

  def entry_order_updated(run_store, _, _, _), do: {:ok, run_store}
end
