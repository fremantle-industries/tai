defmodule Tai.Trading.OrderSubmissionTest do
  use ExUnit.Case, async: true
  doctest Tai.Trading.OrderSubmission

  alias Tai.Trading.{Order, OrderSubmission, TimeInForce}

  test "buy_limit returns a limit submission for the buy side" do
    assert OrderSubmission.buy_limit(
             :my_test_account,
             :my_symbol,
             10.1,
             0.1,
             TimeInForce.fill_or_kill()
           ) == %OrderSubmission{
             account_id: :my_test_account,
             symbol: :my_symbol,
             side: Order.buy(),
             type: Order.limit(),
             time_in_force: TimeInForce.fill_or_kill(),
             price: 10.1,
             size: 0.1
           }
  end

  test "sell_limit returns a limit submission for the buy side" do
    assert OrderSubmission.sell_limit(
             :my_test_account,
             :my_symbol,
             10.1,
             0.1,
             TimeInForce.fill_or_kill()
           ) ==
             %OrderSubmission{
               account_id: :my_test_account,
               symbol: :my_symbol,
               side: Order.sell(),
               type: Order.limit(),
               time_in_force: TimeInForce.fill_or_kill(),
               price: 10.1,
               size: 0.1
             }
  end
end
