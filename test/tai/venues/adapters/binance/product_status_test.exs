defmodule Tai.VenueAdapters.Binance.ProductStatusTest do
  use ExUnit.Case, async: true

  describe "#normalize" do
    test "returns an ok tuple for a supported status" do
      assert Tai.VenueAdapters.Binance.ProductStatus.normalize("PRE_TRADING") ==
               {:ok, Tai.Venues.ProductStatus.pre_trading()}

      assert Tai.VenueAdapters.Binance.ProductStatus.normalize("TRADING") ==
               {:ok, Tai.Venues.ProductStatus.trading()}

      assert Tai.VenueAdapters.Binance.ProductStatus.normalize("POST_TRADING") ==
               {:ok, Tai.Venues.ProductStatus.post_trading()}

      assert Tai.VenueAdapters.Binance.ProductStatus.normalize("END_OF_DAY") ==
               {:ok, Tai.Venues.ProductStatus.end_of_day()}

      assert Tai.VenueAdapters.Binance.ProductStatus.normalize("HALT") ==
               {:ok, Tai.Venues.ProductStatus.halt()}

      assert Tai.VenueAdapters.Binance.ProductStatus.normalize("AUCTION_MATCH") ==
               {:ok, Tai.Venues.ProductStatus.auction_match()}

      assert Tai.VenueAdapters.Binance.ProductStatus.normalize("BREAK") ==
               {:ok, Tai.Venues.ProductStatus.break()}
    end

    test "returns an error tuple for an unsupported status" do
      assert Tai.VenueAdapters.Binance.ProductStatus.normalize("UNSUPPORTED") ==
               {:error, :unknown_status}
    end
  end
end
