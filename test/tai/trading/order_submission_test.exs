defmodule Tai.Trading.OrderSubmissionTest do
  use ExUnit.Case, async: true
  doctest Tai.Trading.OrderSubmission

  alias Tai.Trading.{Order, OrderSubmission}

  test "buy_limit returns a limit submission for the buy side" do
    assert OrderSubmission.buy_limit(:my_exchange, :my_symbol, 10.1, 0.1) == %OrderSubmission{
             exchange_id: :my_exchange,
             symbol: :my_symbol,
             side: Order.buy(),
             type: Order.limit(),
             price: 10.1,
             size: 0.1
           }
  end

  test "sell_limit returns a limit submission for the buy side" do
    assert OrderSubmission.sell_limit(:my_exchange, :my_symbol, 10.1, 0.1) == %OrderSubmission{
             exchange_id: :my_exchange,
             symbol: :my_symbol,
             side: Order.sell(),
             type: Order.limit(),
             price: 10.1,
             size: 0.1
           }
  end
end
