defmodule Tai.Advisors.ConfigTest do
  use ExUnit.Case
  doctest Tai.Advisors.Config

  alias Tai.Advisors.Config

  test "all returns the application config" do
    assert Config.all() == [
             %{
               id: :create_and_cancel_pending_order,
               supervisor: Examples.Advisors.CreateAndCancelPendingOrder.Supervisor,
               order_books: "test_feed_a test_feed_b.eth_usd"
             },
             %{
               id: :fill_or_kill_orders,
               supervisor: Examples.Advisors.FillOrKillOrders.Supervisor,
               order_books: "test_feed_a test_feed_b.eth_usd"
             },
             %{
               id: :log_spread_advisor,
               supervisor: Examples.Advisors.LogSpread.Supervisor,
               order_books: "*"
             }
           ]
  end

  test "find returns the config for the matching advisor or nil if it doesn't exist" do
    assert Config.find(:log_spread_advisor) == %{
             id: :log_spread_advisor,
             supervisor: Examples.Advisors.LogSpread.Supervisor,
             order_books: "*"
           }

    assert Config.find(:i_dont_exist) == nil
  end

  test "order_books returns a map of feeds with books for the given advisor id" do
    assert Config.order_books(:log_spread_advisor) == %{
             test_feed_a: [:btc_usd, :ltc_usd],
             test_feed_b: [:eth_usd, :ltc_usd]
           }

    assert Config.order_books(:create_and_cancel_pending_order) == %{
             test_feed_a: [:btc_usd, :ltc_usd],
             test_feed_b: [:eth_usd]
           }
  end
end
