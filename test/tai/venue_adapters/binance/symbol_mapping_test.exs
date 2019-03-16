defmodule Tai.VenueAdapters.Binance.SymbolMappingTest do
  use ExUnit.Case, async: true
  doctest Tai.VenueAdapters.Binance.SymbolMapping

  test "to_binance returns a valid string for the symbol on Binance" do
    assert Tai.VenueAdapters.Binance.SymbolMapping.to_binance(:btc_usdt) == "BTCUSDT"
    assert Tai.VenueAdapters.Binance.SymbolMapping.to_binance(:BTC_USDT) == "BTCUSDT"
  end

  describe "#to_tai" do
    test "downcases and converts the value to an atom" do
      assert Tai.VenueAdapters.Binance.SymbolMapping.to_tai("FOOBAR") == :foobar
    end

    test "handles btc markets" do
      assert Tai.VenueAdapters.Binance.SymbolMapping.to_tai("LTCBTC") == :ltc_btc
    end

    test "handles eth markets" do
      assert Tai.VenueAdapters.Binance.SymbolMapping.to_tai("BNBETH") == :bnb_eth
    end

    test "handles bnb markets" do
      assert Tai.VenueAdapters.Binance.SymbolMapping.to_tai("EOSBNB") == :eos_bnb
    end

    test "handles usdt markets" do
      assert Tai.VenueAdapters.Binance.SymbolMapping.to_tai("BTCUSDT") == :btc_usdt
    end
  end
end
