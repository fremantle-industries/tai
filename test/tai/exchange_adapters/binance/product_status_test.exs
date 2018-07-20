defmodule Tai.ExchangeAdapters.Binance.ProductStatusTest do
  use ExUnit.Case, async: true

  describe "#tai_status" do
    test "returns an ok tuple for a supported status" do
      assert Tai.ExchangeAdapters.Binance.ProductStatus.tai_status("PRE_TRADING") ==
               {:ok, Tai.Exchanges.ProductStatus.pre_trading()}

      assert Tai.ExchangeAdapters.Binance.ProductStatus.tai_status("TRADING") ==
               {:ok, Tai.Exchanges.ProductStatus.trading()}

      assert Tai.ExchangeAdapters.Binance.ProductStatus.tai_status("POST_TRADING") ==
               {:ok, Tai.Exchanges.ProductStatus.post_trading()}

      assert Tai.ExchangeAdapters.Binance.ProductStatus.tai_status("END_OF_DAY") ==
               {:ok, Tai.Exchanges.ProductStatus.end_of_day()}

      assert Tai.ExchangeAdapters.Binance.ProductStatus.tai_status("HALT") ==
               {:ok, Tai.Exchanges.ProductStatus.halt()}

      assert Tai.ExchangeAdapters.Binance.ProductStatus.tai_status("AUCTION_MATCH") ==
               {:ok, Tai.Exchanges.ProductStatus.auction_match()}

      assert Tai.ExchangeAdapters.Binance.ProductStatus.tai_status("BREAK") ==
               {:ok, Tai.Exchanges.ProductStatus.break()}
    end

    test "returns an error tuple for and unsupported status" do
      assert Tai.ExchangeAdapters.Binance.ProductStatus.tai_status("UNSUPPORTED") ==
               {:error, :unknown_status}
    end
  end
end
