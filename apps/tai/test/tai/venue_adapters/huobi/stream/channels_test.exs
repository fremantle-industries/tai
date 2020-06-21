defmodule Tai.VenueAdapters.Huobi.Stream.ChannelsTest do
  use ExUnit.Case, async: true
  alias Tai.VenueAdapters.Huobi.Stream.Channels

  describe ".market_depth/1" do
    test "returns the venue channel name to stream order book changes" do
      product = struct(Tai.Venues.Product, venue_base: "BTC", alias: "this_week")
      assert Channels.market_depth(product) == {:ok, "market.BTC_CW.depth.size_20.high_freq"}
    end

    test "returns an error when the product alias type is not handled" do
      product = struct(Tai.Venues.Product, venue_base: "BTC", alias: "unknown")
      assert Channels.market_depth(product) == {:error, :unhandled_alias}
    end
  end
end
