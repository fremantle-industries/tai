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
    # bull
    bull_usd_market = build_market(name: "BULL/USD", type: "spot")
    bull_usd_product = VenueAdapters.Ftx.Product.build(bull_usd_market, @venue, @options)
    assert bull_usd_product.type == :leveraged_token

    bull_usdt_market = build_market(name: "BULL/USDT", type: "spot")
    bull_usdt_product = VenueAdapters.Ftx.Product.build(bull_usdt_market, @venue, @options)
    assert bull_usdt_product.type == :leveraged_token

    ada_bull_usd_market = build_market(name: "ADABULL/USD", type: "spot")
    ada_bull_usd_product = VenueAdapters.Ftx.Product.build(ada_bull_usd_market, @venue, @options)
    assert ada_bull_usd_product.type == :leveraged_token

    # bear
    bear_usd_market = build_market(name: "BEAR/USD", type: "spot")
    bear_usd_product = VenueAdapters.Ftx.Product.build(bear_usd_market, @venue, @options)
    assert bear_usd_product.type == :leveraged_token

    bear_usdt_market = build_market(name: "BEAR/USDT", type: "spot")
    bear_usdt_product = VenueAdapters.Ftx.Product.build(bear_usdt_market, @venue, @options)
    assert bear_usdt_product.type == :leveraged_token

    ada_bear_usd_market = build_market(name: "ADABEAR/USD", type: "spot")
    ada_bear_usd_product = VenueAdapters.Ftx.Product.build(ada_bear_usd_market, @venue, @options)
    assert ada_bear_usd_product.type == :leveraged_token

    # hedge
    hedge_usd_market = build_market(name: "HEDGE/USD", type: "spot")
    hedge_usd_product = VenueAdapters.Ftx.Product.build(hedge_usd_market, @venue, @options)
    assert hedge_usd_product.type == :leveraged_token

    hedge_usdt_market = build_market(name: "HEDGE/USDT", type: "spot")
    hedge_usdt_product = VenueAdapters.Ftx.Product.build(hedge_usdt_market, @venue, @options)
    assert hedge_usdt_product.type == :leveraged_token

    ada_hedge_usd_market = build_market(name: "ADAHEDGE/USD", type: "spot")
    ada_hedge_usd_product = VenueAdapters.Ftx.Product.build(ada_hedge_usd_market, @venue, @options)
    assert ada_hedge_usd_product.type == :leveraged_token

    # half
    half_usd_market = build_market(name: "HALF/USD", type: "spot")
    half_usd_product = VenueAdapters.Ftx.Product.build(half_usd_market, @venue, @options)
    assert half_usd_product.type == :leveraged_token

    half_usdt_market = build_market(name: "HALF/USDT", type: "spot")
    half_usdt_product = VenueAdapters.Ftx.Product.build(half_usdt_market, @venue, @options)
    assert half_usdt_product.type == :leveraged_token

    ada_half_usd_market = build_market(name: "ADAHALF/USD", type: "spot")
    ada_half_usd_product = VenueAdapters.Ftx.Product.build(ada_half_usd_market, @venue, @options)
    assert ada_half_usd_product.type == :leveraged_token
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
