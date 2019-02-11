defmodule Tai.TestSupport.Mocks.Responses.Orders.Error do
  alias Tai.TestSupport.Mocks

  @type buy_limit :: Tai.Trading.OrderSubmissions.BuyLimitGtc.t()
  @type sell_limit :: Tai.Trading.OrderSubmissions.SellLimitGtc.t()
  @type submission :: buy_limit | sell_limit
  @type reason :: term

  @spec raise(submission, reason) :: :ok
  def raise(submission, reason) do
    order = Tai.Trading.BuildOrderFromSubmission.build!(submission)

    key =
      {Tai.Trading.OrderResponse,
       [
         symbol: order.symbol,
         price: order.price,
         size: order.qty,
         time_in_force: order.time_in_force
       ]}

    Mocks.Server.insert(key, {:raise, reason})
  end
end
