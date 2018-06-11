defmodule Examples.Advisors.CreateAndCancelPendingOrder.Advisor do
  use Tai.Advisor

  require Logger

  def handle_inside_quote(:gdax, symbol, _inside_quote, _changes, _state) do
    if Tai.Trading.OrderStore.count() == 0 do
      Tai.Trading.OrderPipeline.buy_limit(
        :gdax,
        symbol,
        100.1,
        0.1,
        :fok,
        &order_updated/2
      )
    end

    :ok
  end

  def handle_inside_quote(_, _, _, _, _), do: nil

  def order_updated(
        %Tai.Trading.Order{status: :enqueued},
        %Tai.Trading.Order{status: :pending} = pending_order
      ) do
    Tai.Trading.OrderPipeline.cancel(pending_order)
  end

  def order_updated(_previous_order, _updated_order), do: nil
end
