defmodule Support.Advisors.SpreadCapture do
  use Tai.Advisor

  alias Tai.Advisor
  alias Tai.Trading.{Orders, OrderStatus}

  require Logger

  def handle_order_book_changes(order_book_feed_id, symbol, changes, state) do
    Logger.debug "[#{state.advisor_id |> Advisor.to_name}] handle_order_book_changes - order_book_feed_id: #{order_book_feed_id}, symbol: #{symbol}, changes: #{inspect changes}"
  end

  def handle_inside_quote(order_book_feed_id, symbol, bid, ask, changes, state) do
    Logger.debug "[#{state.advisor_id |> Advisor.to_name}] handle_inside_quote - order_book_feed_id: #{order_book_feed_id}, symbol: #{symbol}, bid/ask: #{inspect bid}/#{inspect ask}, changes: #{inspect changes}, state: #{inspect state}"

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

  def handle_order_create_ok(order, state) do
    Logger.info "[#{state.advisor_id |> Advisor.to_name}] handle_order_create_ok - order: #{inspect order}"
  end

  def handle_order_create_error(reason, order, state) do
    Logger.warn "[#{state.advisor_id |> Advisor.to_name}] handle_order_create_error - reason: #{inspect reason}, order: #{inspect order}"
  end
end
