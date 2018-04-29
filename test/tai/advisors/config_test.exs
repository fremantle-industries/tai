defmodule Tai.Advisors.ConfigTest do
  use ExUnit.Case
  doctest Tai.Advisors.Config

  alias Tai.Advisors.Config

  test "all returns the application config" do
    assert Config.all() == %{
             test_advisor_a: [
               module: Examples.Advisors.CreateAndCancelPendingOrder,
               order_books: %{
                 test_feed_a: [:btcusd, :ltcusd],
                 test_feed_b: [:ethusd, :ltcusd]
               },
               exchanges: [:test_exchange_a, :test_exchange_b]
             ],
             test_advisor_b: [
               module: Examples.Advisors.CreateAndCancelPendingOrder,
               order_books: %{
                 test_feed_a: [:btcusd],
                 test_feed_b: [:ethusd]
               }
             ]
           }
  end

  test "all returns an empty map when no advisors have been configured" do
    assert Config.all(nil) == %{}
  end

  test "modules returns a keyword list of id and module" do
    assert Config.modules() == [
             test_advisor_a: Examples.Advisors.CreateAndCancelPendingOrder,
             test_advisor_b: Examples.Advisors.CreateAndCancelPendingOrder
           ]
  end

  test "order_books returns a map of feed ids with a list of symbols for the advisor id" do
    assert Config.order_books(:test_advisor_a) == %{
             test_feed_a: [:btcusd, :ltcusd],
             test_feed_b: [:ethusd, :ltcusd]
           }
  end

  test "order_books returns nil when the advisor doesn't exist" do
    assert Config.order_books(:test_advisor_doesnt_exist) == nil
  end

  test "exchanges returns a list of exchanges" do
    assert Config.exchanges(:test_advisor_a) == [:test_exchange_a, :test_exchange_b]
  end

  test "exchanges returns an empty list when it's not supplied" do
    assert Config.exchanges(:test_advisor_b) == []
  end
end
