defmodule Tai.ExchangeAdapters.Gdax.ProductTest do
  use ExUnit.Case, async: true
  doctest Tai.ExchangeAdapters.Gdax.Product

  test "strips hyphens, downcases and returns a symbol" do
    assert Tai.ExchangeAdapters.Gdax.Product.to_symbol("BTC-USD") == :btc_usd
  end
end
