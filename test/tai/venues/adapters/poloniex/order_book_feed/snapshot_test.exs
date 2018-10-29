defmodule Tai.VenueAdapters.Poloniex.OrderBookFeed.SnapshotTest do
  use ExUnit.Case, async: true

  alias Tai.VenueAdapters.Poloniex.OrderBookFeed

  test "normalize converts a map of prices and sizes into a map of price level tuples" do
    processed_at = Timex.now()
    data = %{"100.1" => "1.2", "100.0" => "0.13"}

    assert OrderBookFeed.Snapshot.normalize(data, processed_at) == %{
             100.0 => {0.13, processed_at, nil},
             100.1 => {1.2, processed_at, nil}
           }
  end
end
