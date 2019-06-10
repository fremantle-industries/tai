defmodule Tai.VenueAdapters.Binance.ProductsTest do
  use ExUnit.Case, async: false
  alias Tai.VenueAdapters.Binance.Products

  describe ".to_symbol" do
    test "upcases and stripts underscores" do
      assert Products.to_symbol(:btc_usdt) == "BTCUSDT"
      assert Products.to_symbol(:BTC_USDT) == "BTCUSDT"
    end
  end
end
