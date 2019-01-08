defmodule Tai.TestSupport.Mocks.Responses.Orders.GoodTillCancel do
  alias Tai.TestSupport.Mocks

  @type order :: Tai.Trading.Order.t()
  @type buy_limit :: Tai.Trading.OrderSubmissions.BuyLimitGtc.t()
  @type sell_limit :: Tai.Trading.OrderSubmissions.SellLimitGtc.t()
  @type submission :: buy_limit | sell_limit
  @type venue_order_id :: String.t()

  @spec unfilled(venue_order_id, submission) :: :ok
  def unfilled(venue_order_id, submission) do
    order_response = %Tai.Trading.OrderResponse{
      id: venue_order_id,
      time_in_force: :gtc,
      status: :open,
      original_size: submission.qty,
      cumulative_qty: nil,
      timestamp: Timex.now()
    }

    key =
      {Tai.Trading.OrderResponse,
       [
         symbol: submission.product_symbol,
         price: submission.price,
         size: submission.qty,
         time_in_force: :gtc
       ]}

    Mocks.Server.insert(key, order_response)
  end

  @spec amend_price(order, number) :: :ok
  def amend_price(order, _price) do
    order_response = %Tai.Trading.OrderResponse{
      id: order.venue_order_id,
      time_in_force: :gtc,
      status: :open,
      original_size: order.qty,
      cumulative_qty: Decimal.new(0),
      timestamp: Timex.now()
      # TODO: price
    }

    key = {Tai.Trading.OrderResponse, :amend_order, order.venue_order_id}
    Mocks.Server.insert(key, order_response)
  end

  @spec amend_price_and_qty(order, number, number) :: :ok
  def amend_price_and_qty(order, _price, qty) do
    order_response = %Tai.Trading.OrderResponse{
      id: order.venue_order_id,
      time_in_force: :gtc,
      status: :open,
      original_size: qty,
      cumulative_qty: Decimal.new(0),
      timestamp: Timex.now()
      # TODO: price
    }

    key = {Tai.Trading.OrderResponse, :amend_order, order.venue_order_id}
    Mocks.Server.insert(key, order_response)
  end

  @spec canceled(venue_order_id) :: :ok
  def canceled(venue_order_id) do
    Mocks.Server.insert(venue_order_id, :cancel_ok)
  end
end
