defmodule Examples.Advisors.CreateAndCancelPendingOrder.Advisor do
  use Tai.Advisor

  def handle_inside_quote(feed_id, symbol, _inside_quote, _changes, _state) do
    if Tai.Trading.OrderStore.count() == 0 do
      Tai.Trading.OrderPipeline.buy_limit(
        feed_id,
        :main,
        symbol,
        100.1,
        0.1,
        :gtc,
        &order_updated/2
      )
    end

    :ok
  end

  def order_updated(
        %Tai.Trading.Order{status: :enqueued},
        %Tai.Trading.Order{status: :pending} = pending_order
      ) do
    Tai.Trading.OrderPipeline.cancel(pending_order)
  end

  def order_updated(_previous_order, _updated_order), do: nil
end
