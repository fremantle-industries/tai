defmodule Tai.TestSupport.Mocks.Responses.Orders.GoodTillCancel do
  alias Tai.TestSupport.Mocks

  @type buy_limit :: Tai.Trading.OrderSubmissions.BuyLimitGtc.t()
  @type sell_limit :: Tai.Trading.OrderSubmissions.SellLimitGtc.t()
  @type submission :: buy_limit | sell_limit
  @type venue_order_id :: String.t()

  @spec unfilled(venue_order_id, submission) :: :ok
  def unfilled(server_id, submission) do
    order_response = %Tai.Trading.OrderResponse{
      id: server_id,
      time_in_force: :gtc,
      status: :open,
      original_size: submission.qty,
      cumulative_qty: nil
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

  @spec canceled(venue_order_id) :: :ok
  def canceled(venue_order_id) do
    Mocks.Server.insert(venue_order_id, :cancel_ok)
  end
end
