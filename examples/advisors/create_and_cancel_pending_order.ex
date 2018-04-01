defmodule Examples.Advisors.CreateAndCancelPendingOrder do
  use Tai.Advisor

  alias Tai.Advisor
  alias Tai.Trading.{Orders, OrderStatus}

  require Logger

  def handle_inside_quote(:gdax, symbol, inside_quote, changes, state) do
    Logger.debug fn ->
      :io_lib.format(
        "[~s] handle_inside_quote - order_book_feed_id: ~s, symbol: ~s, quote: ~s, changes: ~s, state: ~s",
        [
          state.advisor_id |> Advisor.to_name,
          :gdax,
          symbol,
          inspect(inside_quote),
          inspect(changes),
          inspect(state)
        ]
      )
    end

    cond do
      Orders.count() == 0 ->
        Logger.info "[#{state.advisor_id |> Advisor.to_name}] handle_inside_quote - create buy limit order on :gdax"
        {:ok, %{limit_orders: [{:gdax, :btcusd, 100.1, 0.1}]}}
      (pending_orders = Orders.where(status: OrderStatus.pending)) |> Enum.count > 0 ->
        Logger.info "[#{state.advisor_id |> Advisor.to_name}] handle_inside_quote - cancel pending orders: #{inspect pending_orders}"
        cancel_orders = pending_orders |> Enum.map(& &1.client_id)
        {:ok, %{cancel_orders: cancel_orders}}
      true ->
        :ok
    end
  end
  def handle_inside_quote(order_book_feed_id, symbol, inside_quote, changes, state) do
    Logger.debug fn ->
      :io_lib.format(
        "[~s] handle_inside_quote - order_book_feed_id: ~s, symbol: ~s, quote: ~s, changes: ~s, state: ~s",
        [
          state.advisor_id |> Advisor.to_name,
          order_book_feed_id,
          symbol,
          inspect(inside_quote),
          inspect(changes),
          inspect(state)
        ]
      )
    end
  end

  def handle_order_create_ok(order, state) do
    Logger.info "[#{state.advisor_id |> Advisor.to_name}] handle_order_create_ok - order: #{inspect order}"
  end

  def handle_order_create_error(reason, order, state) do
    Logger.warn "[#{state.advisor_id |> Advisor.to_name}] handle_order_create_error - reason: #{inspect reason}, order: #{inspect order}"
  end
end
