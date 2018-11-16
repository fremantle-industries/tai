defmodule Examples.Advisors.FillOrKillOrders.Advisor do
  @moduledoc """
  Example advisor that demonstrates how to use fill or kill limit orders. It 
  logs a success message when the order is successfully filled
  """

  use Tai.Advisor

  require Logger

  def handle_inside_quote(feed_id, symbol, _inside_quote, _changes, _state) do
    if Tai.Trading.OrderStore.count() == 0 do
      Tai.Trading.OrderPipeline.buy_limit(
        feed_id,
        :main,
        symbol,
        100.1,
        0.1,
        :fok,
        &order_updated/2
      )
    end

    :ok
  end

  def order_updated(
        %Tai.Trading.Order{status: :enqueued},
        %Tai.Trading.Order{status: :filled} = updated_order
      ) do
    Logger.info("successfully filled order #{inspect(updated_order)}")
  end

  def order_updated(_previous_order, _updated_order), do: nil
end
