defmodule Tai.TestSupport.Mocks.Responses.Orders.FillOrKill do
  alias Tai.TestSupport.Mocks

  @type buy_limit :: Tai.Trading.OrderSubmissions.BuyLimitFok.t()
  @type sell_limit :: Tai.Trading.OrderSubmissions.SellLimitFok.t()
  @type submission :: buy_limit | sell_limit
  @type venue_order_id :: Tai.Trading.Order.venue_order_id()

  @spec expired(submission) :: :ok
  def expired(submission) do
    order_response = %Tai.Trading.OrderResponse{
      id: UUID.uuid4(),
      time_in_force: :fok,
      status: :expired,
      original_size: submission.qty,
      cumulative_qty: Decimal.new(0),
      timestamp: Timex.now()
    }

    key =
      {Tai.Trading.OrderResponse,
       [
         symbol: submission.product_symbol,
         price: submission.price,
         size: submission.qty,
         time_in_force: :fok
       ]}

    Mocks.Server.insert(key, order_response)
  end

  @spec filled(venue_order_id, submission) :: :ok
  def filled(venue_order_id, submission) do
    order_response = %Tai.Trading.OrderResponse{
      id: venue_order_id,
      time_in_force: :fok,
      status: :filled,
      original_size: submission.qty,
      cumulative_qty: submission.qty,
      timestamp: Timex.now()
    }

    key =
      {Tai.Trading.OrderResponse,
       [
         symbol: submission.product_symbol,
         price: submission.price,
         size: submission.qty,
         time_in_force: :fok
       ]}

    Mocks.Server.insert(key, order_response)
  end

  @spec filled(submission) :: :ok
  def filled(submission), do: filled(UUID.uuid4(), submission)
end
