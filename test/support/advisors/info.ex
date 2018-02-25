defmodule Support.Advisors.Info do
  use Tai.Advisor

  require Logger

  def handle_order_book_changes(feed_id, symbol, changes, state) do
    Logger.debug "[#{state.advisor_id |> Tai.Advisor.to_name}] handle_order_book_changes - feed_id: #{feed_id}, symbol: #{symbol}, changes: #{inspect changes}"

    :ok
  end

  def handle_inside_quote(feed_id, symbol, bid, ask, changes, state) do
    Logger.debug "[#{state.advisor_id |> Tai.Advisor.to_name}] handle_inside_quote - feed_id: #{feed_id}, symbol: #{symbol}, bid/ask: #{inspect bid}/#{inspect ask}, changes: #{inspect changes}"

    :ok
  end
end
