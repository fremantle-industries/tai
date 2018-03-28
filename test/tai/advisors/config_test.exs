defmodule Tai.Advisors.ConfigTest do
  use ExUnit.Case
  doctest Tai.Advisors.Config

  alias Tai.Advisors.Config

  test "all returns the application config" do
    assert Config.all == %{
      test_advisor_a: [
        server: Support.Advisors.SpreadCapture,
        order_books: %{
          test_feed_a: [:btcusd, :ltcusd],
          test_feed_b: [:ethusd, :ltcusd]
        }
      ],
      test_advisor_b: [
        server: Support.Advisors.SpreadCapture,
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

  test "servers returns a keyword list of id and server" do
    assert Config.servers == [
      test_advisor_a: Support.Advisors.SpreadCapture,
      test_advisor_b: Support.Advisors.SpreadCapture
    ]
  end

  test "order_books returns a map of feed ids with a list of symbols for the advisor id" do
    assert Config.order_books(:test_advisor_a) == %{
      test_feed_a: [:btcusd, :ltcusd],
      test_feed_b: [:ethusd, :ltcusd],
    }
  end

  test "order_books returns nil when the advisor doesn't exist" do
    assert Config.order_books(:test_advisor_doesnt_exist) == nil
  end
end
