defmodule Tai.TestSupport.Mocks.Responses.Orders.Error do
  alias Tai.TestSupport.Mocks

  @type buy_limit :: Tai.Trading.OrderSubmissions.BuyLimitGtc.t()
  @type sell_limit :: Tai.Trading.OrderSubmissions.SellLimitGtc.t()
  @type submission :: buy_limit | sell_limit
  @type order :: Tai.Trading.Order.t()
  @type amend_attrs :: map
  @type reason :: term

  @spec create_raise(submission, reason) :: :ok
  def create_raise(submission, reason) do
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

  @spec amend_raise(order, amend_attrs, reason) :: :ok
  def amend_raise(%Tai.Trading.Order{} = order, attrs, reason) do
    match_attrs =
      %{venue_order_id: order.venue_order_id}
      |> Map.merge(attrs)

    key = {Tai.Trading.OrderResponses.Amend, match_attrs}

    Mocks.Server.insert(key, {:raise, reason})
  end
end
