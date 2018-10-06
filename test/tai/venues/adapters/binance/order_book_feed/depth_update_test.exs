defmodule Tai.VenueAdapters.Binance.OrderBookFeed.DepthUpdateTest do
  use ExUnit.Case, async: true
  doctest Tai.VenueAdapters.Binance.OrderBookFeed.DepthUpdate

  alias Tai.VenueAdapters.Binance.OrderBookFeed

  test "normalize returns a map of price levels" do
    processed_at = Timex.now()
    server_changed_at = Timex.now()

    changes = [
      ["0.01891900", "3.15000000", []],
      ["0.01891000", "1.57000000", []]
    ]

    assert OrderBookFeed.DepthUpdate.normalize(changes, processed_at, server_changed_at) == %{
             0.018919 => {3.15, processed_at, server_changed_at},
             0.01891 => {1.57, processed_at, server_changed_at}
           }
  end
end
