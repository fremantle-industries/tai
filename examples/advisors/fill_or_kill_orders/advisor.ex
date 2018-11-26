defmodule Examples.Advisors.FillOrKillOrders.Advisor do
  @moduledoc """
  Example advisor that demonstrates how to use fill or kill limit orders. It 
  logs a success message when the order is successfully filled
  """

  use Tai.Advisor

  require Logger

  def handle_inside_quote(venue_id, product_symbol, _inside_quote, _changes, _state) do
    if Tai.Trading.OrderStore.count() == 0 do
      Tai.Trading.OrderPipeline.enqueue(%Tai.Trading.Orders.BuyLimit{
        venue_id: venue_id,
        account_id: :main,
        product_symbol: product_symbol,
        price: 100.1,
        qty: 0.1,
        time_in_force: :fok,
        order_updated_callback: &order_updated/2
      })
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
