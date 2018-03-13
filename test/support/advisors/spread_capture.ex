defmodule Support.Advisors.SpreadCapture do
  use Tai.Advisor

  require Logger

  def handle_order_book_changes(feed_id, symbol, changes, state) do
    Logger.debug "[#{state.advisor_id |> Tai.Advisor.to_name}] handle_order_book_changes - feed_id: #{feed_id}, symbol: #{symbol}, changes: #{inspect changes}"
  end

  def handle_inside_quote(feed_id, symbol, bid, ask, changes, state) do
    Logger.debug "[#{state.advisor_id |> Tai.Advisor.to_name}] handle_inside_quote - feed_id: #{feed_id}, symbol: #{symbol}, bid/ask: #{inspect bid}/#{inspect ask}, changes: #{inspect changes}"

    if Tai.Trading.Orders.count() == 0 do
      Logger.info "[#{state.advisor_id |> Tai.Advisor.to_name}] handle_inside_quote - create buy limit order on :gdax"
      {:ok, %{limit_orders: [{:gdax, :btcusd, 100.1, 0.1}]}}
    else
      :ok
    end
  end

  def handle_order_enqueued(order, state) do
    Logger.info "[#{state.advisor_id |> Tai.Advisor.to_name}] handle_order_enqueued - order: #{inspect order}"
  end

  def handle_order_create_ok(order, state) do
    Logger.info "[#{state.advisor_id |> Tai.Advisor.to_name}] handle_order_create_ok - order: #{inspect order}"
  end

  def handle_order_create_error(reason, order, state) do
    Logger.warn "[#{state.advisor_id |> Tai.Advisor.to_name}] handle_order_create_error - reason: #{inspect reason}, order: #{inspect order}"
  end
end
