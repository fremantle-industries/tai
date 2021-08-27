defmodule Tai.VenueAdapters.Ftx.ProductTest do
  use ExUnit.Case, async: false
  alias Tai.VenueAdapters

  @venue :venue_a
  @options struct(VenueAdapters.Ftx.Product.Options)

  test ".build/2 can parse spot products" do
    market = build_market(name: "BTC/USD", type: "spot")
    product = VenueAdapters.Ftx.Product.build(market, @venue, @options)

    assert product.type == :spot
  end

  test ".build/2 can parse futures products" do
    market = build_market(name: "BTC-1231")
    product = VenueAdapters.Ftx.Product.build(market, @venue, @options)

    assert product.type == :future
  end

  test ".build/2 can parse swap products" do
    market = build_market(name: "BTC-PERP")
    product = VenueAdapters.Ftx.Product.build(market, @venue, @options)

    assert product.type == :swap
  end

  test ".build/2 can parse leveraged_token products" do
    usd_market = build_market(name: "BULL/USD")
    usdt_market = build_market(name: "BULL/USDT")
    usd_product = VenueAdapters.Ftx.Product.build(usd_market, @venue, @options)
    usdt_product = VenueAdapters.Ftx.Product.build(usdt_market, @venue, @options)

    assert usd_product.type == :leveraged_token
    assert usdt_product.type == :leveraged_token
  end

  test ".build/2 can parse move products" do
    market = build_market(name: "BTC-MOVE-1031")
    product = VenueAdapters.Ftx.Product.build(market, @venue, @options)

    assert product.type == :move
  end

  test ".build/2 can parse bvol products" do
    market = build_market(name: "BVOL/BTC")
    product = VenueAdapters.Ftx.Product.build(market, @venue, @options)

    assert product.type == :bvol
  end

  test ".build/2 can parse ibvol products" do
    market = build_market(name: "IBVOL/BTC")
    product = VenueAdapters.Ftx.Product.build(market, @venue, @options)

    assert product.type == :ibvol
  end

  @default_attrs [
    base_currency: "BTC",
    quote_currency: "USD",
    underlying: "BTC",
    enabled: true,
    restricted: false,
    price_increment: 0.001,
    size_increment: 0.001,
    min_provide_size: 0.001
  ]
  defp build_market(attrs) do
    combined_attrs = Keyword.merge(@default_attrs, attrs)
    struct(ExFtx.Market, combined_attrs)
  end
end
