defmodule Tai.TestSupport.Mocks.Orders.GoodTillCancel do
  @spec unfilled(
          server_id: String.t(),
          symbol: atom,
          price: Decimal.t(),
          original_size: Decimal.t()
        ) :: :ok
  def unfilled(server_id: server_id, symbol: symbol, price: price, original_size: original_size) do
    order_response = %Tai.Trading.OrderResponse{
      id: server_id,
      time_in_force: Tai.Trading.TimeInForce.good_til_canceled(),
      status: Tai.Trading.OrderStatus.pending(),
      original_size: original_size,
      executed_size: nil
    }

    key = {symbol, price, original_size, order_response.time_in_force}
    :ok = Tai.TestSupport.Mocks.Server.insert(key, order_response)

    :ok
  end

  @spec canceled(server_id: String.t()) :: :ok
  def canceled(server_id: server_id) do
    key = server_id
    :ok = Tai.TestSupport.Mocks.Server.insert(key, :cancel_ok)
    :ok
  end
end
