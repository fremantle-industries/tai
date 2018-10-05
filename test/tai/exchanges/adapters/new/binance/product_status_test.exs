defmodule Tai.ExchangeAdapters.New.Binance.ProductStatusTest do
  use ExUnit.Case, async: true

  describe "#normalize" do
    test "returns an ok tuple for a supported status" do
      assert Tai.ExchangeAdapters.New.Binance.ProductStatus.normalize("PRE_TRADING") ==
               {:ok, Tai.Exchanges.ProductStatus.pre_trading()}

      assert Tai.ExchangeAdapters.New.Binance.ProductStatus.normalize("TRADING") ==
               {:ok, Tai.Exchanges.ProductStatus.trading()}

      assert Tai.ExchangeAdapters.New.Binance.ProductStatus.normalize("POST_TRADING") ==
               {:ok, Tai.Exchanges.ProductStatus.post_trading()}

      assert Tai.ExchangeAdapters.New.Binance.ProductStatus.normalize("END_OF_DAY") ==
               {:ok, Tai.Exchanges.ProductStatus.end_of_day()}

      assert Tai.ExchangeAdapters.New.Binance.ProductStatus.normalize("HALT") ==
               {:ok, Tai.Exchanges.ProductStatus.halt()}

      assert Tai.ExchangeAdapters.New.Binance.ProductStatus.normalize("AUCTION_MATCH") ==
               {:ok, Tai.Exchanges.ProductStatus.auction_match()}

      assert Tai.ExchangeAdapters.New.Binance.ProductStatus.normalize("BREAK") ==
               {:ok, Tai.Exchanges.ProductStatus.break()}
    end

    test "returns an error tuple for an unsupported status" do
      assert Tai.ExchangeAdapters.New.Binance.ProductStatus.normalize("UNSUPPORTED") ==
               {:error, :unknown_status}
    end
  end
end
