defmodule Tai.TestSupport.Mocks.Responses.Orders.ImmediateOrCancel do
  alias Tai.TestSupport.Mocks

  @type buy_limit :: Tai.Trading.OrderSubmissions.BuyLimitIoc.t()
  @type sell_limit :: Tai.Trading.OrderSubmissions.SellLimitIoc.t()
  @type submission :: buy_limit | sell_limit
  @type venue_order_id :: Tai.Trading.Order.venue_order_id()
  @type insert_result :: :ok

  @spec expired(venue_order_id, submission, map) :: insert_result
  def expired(venue_order_id, submission, attrs) do
    qty = submission.qty
    cumulative_qty = attrs |> Map.get(:cumulative_qty, Decimal.new(0))
    avg_price = attrs |> Map.get(:avg_price, Decimal.new(0))

    order_response = %Tai.Trading.OrderResponses.Create{
      id: venue_order_id,
      status: :expired,
      avg_price: avg_price,
      original_size: qty,
      cumulative_qty: cumulative_qty,
      leaves_qty: Decimal.new(0),
      venue_created_at: Timex.now()
    }

    key =
      {Tai.Trading.OrderResponse,
       [
         symbol: submission.product_symbol,
         price: submission.price,
         size: qty,
         time_in_force: :ioc
       ]}

    Mocks.Server.insert(key, order_response)
  end

  @spec expired(venue_order_id, submission) :: insert_result
  def expired(venue_order_id, submission) do
    expired(venue_order_id, submission, %{})
  end

  @spec expired(submission) :: insert_result
  def expired(submission), do: expired(Ecto.UUID.generate(), submission)

  @spec filled(venue_order_id, submission) :: insert_result
  def filled(venue_order_id, submission) do
    order_response = %Tai.Trading.OrderResponses.Create{
      id: venue_order_id,
      status: :filled,
      avg_price: submission.price,
      original_size: submission.qty,
      leaves_qty: Decimal.new(0),
      cumulative_qty: submission.qty,
      venue_created_at: Timex.now()
    }

    key =
      {Tai.Trading.OrderResponse,
       [
         symbol: submission.product_symbol,
         price: submission.price,
         size: submission.qty,
         time_in_force: :ioc
       ]}

    Mocks.Server.insert(key, order_response)
  end

  @spec filled(submission) :: insert_result
  def filled(submission), do: filled(Ecto.UUID.generate(), submission)
end
