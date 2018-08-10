defmodule Tai.TestSupport.Factories.Order do
  def build_invalid_order() do
    %Tai.Trading.Order{
      side: :invalid_side,
      type: :invalid_type,
      client_id: :ignore,
      enqueued_at: :ignore,
      exchange_id: :ignore,
      account_id: :ignore,
      price: :ignore,
      size: :ignore,
      status: :ignore,
      symbol: :ignore,
      time_in_force: :ignore
    }
  end
end
