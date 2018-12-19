defmodule Tai.TestSupport.Mocks.Responses.Orders.FillOrKill do
  alias Tai.TestSupport.Mocks

  @type buy_limit :: Tai.Trading.OrderSubmissions.BuyLimitFok.t()
  @type sell_limit :: Tai.Trading.OrderSubmissions.SellLimitFok.t()
  @type submission :: buy_limit | sell_limit

  @spec expired(submission) :: :ok
  def expired(submission) do
    order_response = %Tai.Trading.OrderResponse{
      id: UUID.uuid4(),
      time_in_force: :fok,
      status: :expired,
      original_size: submission.qty,
      cumulative_qty: Decimal.new(0)
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
  def filled(submission) do
    order_response = %Tai.Trading.OrderResponse{
      id: UUID.uuid4(),
      time_in_force: :fok,
      status: :filled,
      original_size: submission.qty,
      cumulative_qty: submission.qty
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
end
