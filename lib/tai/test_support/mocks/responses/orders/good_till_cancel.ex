defmodule Tai.TestSupport.Mocks.Responses.Orders.GoodTillCancel do
  alias Tai.TestSupport.Mocks

  @type order :: Tai.Trading.Order.t()
  @type buy_limit :: Tai.Trading.OrderSubmissions.BuyLimitGtc.t()
  @type sell_limit :: Tai.Trading.OrderSubmissions.SellLimitGtc.t()
  @type submission :: buy_limit | sell_limit
  @type venue_order_id :: String.t()

  @spec unfilled(venue_order_id, submission) :: :ok
  @deprecated "use Tai.TestSupport.Mocks.Responses.Orders.GoodTillCancel.open/2 instead."
  def unfilled(venue_order_id, submission) do
    open(venue_order_id, submission)
  end

  @spec open(venue_order_id, submission) :: :ok
  def open(venue_order_id, submission) do
    open(venue_order_id, submission, %{})
  end

  @spec open(venue_order_id, submission, map) :: :ok
  def open(venue_order_id, submission, attrs) do
    qty = submission.qty
    cumulative_qty = attrs |> Map.get(:cumulative_qty, Decimal.new(0))
    leaves_qty = Decimal.sub(qty, cumulative_qty)
    avg_price = attrs |> Map.get(:avg_price, Decimal.new(0))

    order_response = %Tai.Trading.OrderResponses.Create{
      id: venue_order_id,
      status: :open,
      avg_price: avg_price,
      original_size: qty,
      leaves_qty: leaves_qty,
      cumulative_qty: cumulative_qty,
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
  def amend_price(order, price) do
    order_response = %Tai.Trading.OrderResponses.Amend{
      id: order.venue_order_id,
      status: :open,
      price: price,
      leaves_qty: order.leaves_qty,
      cumulative_qty: Decimal.new(0),
      venue_updated_at: Timex.now()
    }

    key = {Tai.Trading.OrderResponse, :amend_order, order.venue_order_id}
    Mocks.Server.insert(key, order_response)
  end

  @spec amend_price_and_qty(order, number, number) :: :ok
  def amend_price_and_qty(order, price, qty) do
    order_response = %Tai.Trading.OrderResponses.Amend{
      id: order.venue_order_id,
      status: :open,
      price: price,
      leaves_qty: qty,
      cumulative_qty: Decimal.new(0),
      venue_updated_at: Timex.now()
    }

    key = {Tai.Trading.OrderResponse, :amend_order, order.venue_order_id}
    Mocks.Server.insert(key, order_response)
  end

  @spec canceled(venue_order_id) :: :ok
  def canceled(venue_order_id) do
    Mocks.Server.insert(venue_order_id, :cancel_ok)
  end
end
