defmodule Tai.Trading.OrderTest do
  use ExUnit.Case, async: true
  doctest Tai.Trading.Order

  test "buy_limit? is true for buy side orders with a limit type" do
    buy_limit_order = %Tai.Trading.Order{
      side: Tai.Trading.Order.buy(),
      type: Tai.Trading.Order.limit(),
      client_id: :ignore,
      enqueued_at: :ignore,
      account_id: :ignore,
      price: :ignore,
      size: :ignore,
      status: :ignore,
      symbol: :ignore,
      time_in_force: :ignore
    }

    buy_market_order = %Tai.Trading.Order{
      side: Tai.Trading.Order.buy(),
      type: :market,
      client_id: :ignore,
      enqueued_at: :ignore,
      account_id: :ignore,
      price: :ignore,
      size: :ignore,
      status: :ignore,
      symbol: :ignore,
      time_in_force: :ignore
    }

    sell_limit_order = %Tai.Trading.Order{
      side: Tai.Trading.Order.sell(),
      type: Tai.Trading.Order.limit(),
      client_id: :ignore,
      enqueued_at: :ignore,
      account_id: :ignore,
      price: :ignore,
      size: :ignore,
      status: :ignore,
      symbol: :ignore,
      time_in_force: :ignore
    }

    assert Tai.Trading.Order.buy_limit?(buy_limit_order) == true
    assert Tai.Trading.Order.buy_limit?(buy_market_order) == false
    assert Tai.Trading.Order.buy_limit?(sell_limit_order) == false
  end

  test "sell_limit? is true for sell side orders with a limit type" do
    sell_limit_order = %Tai.Trading.Order{
      side: Tai.Trading.Order.sell(),
      type: Tai.Trading.Order.limit(),
      client_id: :ignore,
      enqueued_at: :ignore,
      account_id: :ignore,
      price: :ignore,
      size: :ignore,
      status: :ignore,
      symbol: :ignore,
      time_in_force: :ignore
    }

    sell_market_order = %Tai.Trading.Order{
      side: Tai.Trading.Order.sell(),
      type: :market,
      client_id: :ignore,
      enqueued_at: :ignore,
      account_id: :ignore,
      price: :ignore,
      size: :ignore,
      status: :ignore,
      symbol: :ignore,
      time_in_force: :ignore
    }

    buy_limit_order = %Tai.Trading.Order{
      side: Tai.Trading.Order.buy(),
      type: Tai.Trading.Order.limit(),
      client_id: :ignore,
      enqueued_at: :ignore,
      account_id: :ignore,
      price: :ignore,
      size: :ignore,
      status: :ignore,
      symbol: :ignore,
      time_in_force: :ignore
    }

    assert Tai.Trading.Order.sell_limit?(sell_limit_order) == true
    assert Tai.Trading.Order.sell_limit?(sell_market_order) == false
    assert Tai.Trading.Order.sell_limit?(buy_limit_order) == false
  end
end
