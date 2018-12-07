defmodule Tai.TestSupport.Mocks.Orders.FillOrKill do
  def expired(symbol: symbol, price: price, original_size: original_size) do
    order_response = %Tai.Trading.OrderResponse{
      id: UUID.uuid4(),
      time_in_force: Tai.Trading.TimeInForce.fill_or_kill(),
      status: :expired,
      original_size: Decimal.new(original_size),
      executed_size: nil
    }

    key = {symbol, price, original_size, order_response.time_in_force}
    :ok = Tai.TestSupport.Mocks.Server.insert(key, order_response)

    :ok
  end

  def filled(symbol: symbol, price: price, original_size: original_size) do
    order_response = %Tai.Trading.OrderResponse{
      id: UUID.uuid4(),
      time_in_force: Tai.Trading.TimeInForce.fill_or_kill(),
      status: :filled,
      original_size: Decimal.new(original_size),
      executed_size: Decimal.new(original_size)
    }

    key = {symbol, price, original_size, order_response.time_in_force}
    :ok = Tai.TestSupport.Mocks.Server.insert(key, order_response)

    :ok
  end
end
