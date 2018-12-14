defmodule Tai.TestSupport.Mocks.Orders.GoodTillCancel do
  @spec unfilled(
          venue_order_id: String.t(),
          symbol: atom,
          price: Decimal.t(),
          original_size: Decimal.t()
        ) :: :ok
  def unfilled(venue_order_id: venue_order_id, symbol: symbol, price: price, original_size: original_size) do
    order_response = %Tai.Trading.OrderResponse{
      id: venue_order_id,
      time_in_force: :gtc,
      status: :open,
      original_size: original_size,
      executed_size: nil
    }

    key = {symbol, price, original_size, order_response.time_in_force}
    :ok = Tai.TestSupport.Mocks.Server.insert(key, order_response)

    :ok
  end

  @spec canceled(venue_order_id: String.t()) :: :ok
  def canceled(venue_order_id: venue_order_id) do
    key = venue_order_id
    :ok = Tai.TestSupport.Mocks.Server.insert(key, :cancel_ok)
    :ok
  end
end
