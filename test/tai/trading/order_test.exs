defmodule Tai.Trading.OrderTest do
  use ExUnit.Case, async: true
  doctest Tai.Trading.Order

  alias Tai.Trading.Order

  test "buy_limit? is true for buy side orders with a limit type" do
    buy_limit_order = %Order{
      side: Order.buy(),
      type: Order.limit(),
      client_id: :ignore,
      enqueued_at: :ignore,
      exchange: :ignore,
      price: :ignore,
      size: :ignore,
      status: :ignore,
      symbol: :ignore
    }

    buy_market_order = %Order{
      side: Order.buy(),
      type: :market,
      client_id: :ignore,
      enqueued_at: :ignore,
      exchange: :ignore,
      price: :ignore,
      size: :ignore,
      status: :ignore,
      symbol: :ignore
    }

    sell_limit_order = %Order{
      side: Order.sell(),
      type: Order.limit(),
      client_id: :ignore,
      enqueued_at: :ignore,
      exchange: :ignore,
      price: :ignore,
      size: :ignore,
      status: :ignore,
      symbol: :ignore
    }

    assert Order.buy_limit?(buy_limit_order) == true
    assert Order.buy_limit?(buy_market_order) == false
    assert Order.buy_limit?(sell_limit_order) == false
  end

  test "sell_limit? is true for sell side orders with a limit type" do
    sell_limit_order = %Order{
      side: Order.sell(),
      type: Order.limit(),
      client_id: :ignore,
      enqueued_at: :ignore,
      exchange: :ignore,
      price: :ignore,
      size: :ignore,
      status: :ignore,
      symbol: :ignore
    }

    sell_market_order = %Order{
      side: Order.sell(),
      type: :market,
      client_id: :ignore,
      enqueued_at: :ignore,
      exchange: :ignore,
      price: :ignore,
      size: :ignore,
      status: :ignore,
      symbol: :ignore
    }

    buy_limit_order = %Order{
      side: Order.buy(),
      type: Order.limit(),
      client_id: :ignore,
      enqueued_at: :ignore,
      exchange: :ignore,
      price: :ignore,
      size: :ignore,
      status: :ignore,
      symbol: :ignore
    }

    assert Order.sell_limit?(sell_limit_order) == true
    assert Order.sell_limit?(sell_market_order) == false
    assert Order.sell_limit?(buy_limit_order) == false
  end
end
