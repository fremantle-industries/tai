defmodule Tai.TestSupport.Mocks.Responses.Orders.Error do
  alias Tai.TestSupport.Mocks

  @type buy_limit :: Tai.Orders.Submissions.BuyLimitGtc.t()
  @type sell_limit :: Tai.Orders.Submissions.SellLimitGtc.t()
  @type submission :: buy_limit | sell_limit
  @type venue_order_id :: Tai.Orders.Order.venue_order_id()
  @type order :: Tai.Orders.Order.t()
  @type amend_attrs :: map
  @type reason :: term

  @spec create_raise(submission, reason) :: :ok
  def create_raise(submission, reason) do
    order = Tai.Orders.Submissions.Factory.build!(submission)

    match_attrs = %{
      symbol: order.product_symbol,
      price: order.price,
      size: order.qty,
      time_in_force: order.time_in_force
    }

    {:create_order, match_attrs}
    |> Mocks.Server.insert({:raise, reason})
  end

  @spec amend_raise(order, amend_attrs, reason) :: :ok
  def amend_raise(%Tai.Orders.Order{} = order, attrs, reason) do
    match_attrs = Map.merge(%{venue_order_id: order.venue_order_id}, attrs)

    {:amend_order, match_attrs}
    |> Mocks.Server.insert({:raise, reason})
  end

  @spec cancel_raise(venue_order_id, reason) :: :ok
  def cancel_raise(venue_order_id, reason) do
    {:cancel_order, venue_order_id}
    |> Mocks.Server.insert({:raise, reason})
  end
end
