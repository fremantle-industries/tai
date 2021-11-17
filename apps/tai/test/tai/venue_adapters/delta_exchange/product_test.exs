defmodule Tai.VenueAdapters.DeltaExchange.ProductTest do
  use ExUnit.Case, async: false
  alias Tai.VenueAdapters

  @venue :venue_a

  test ".build/2 can parse spot products" do
    venue_product = build_venue_product(symbol: "BTC_USDT", contract_type: "spot")
    product = VenueAdapters.DeltaExchange.Product.build(venue_product, @venue)

    assert product.type == :spot
  end

  test ".build/2 can parse futures products" do
    venue_product = build_venue_product(symbol: "BTCUSD_31Dec", contract_type: "futures")
    product = VenueAdapters.DeltaExchange.Product.build(venue_product, @venue)

    assert product.type == :future
  end

  test ".build/2 can parse swap products" do
    perp_venue_product = build_venue_product(symbol: "BTCUSD", contract_type: "perpetual_futures")
    perp_product = VenueAdapters.DeltaExchange.Product.build(perp_venue_product, @venue)
    assert perp_product.type == :swap

    ir_venue_product = build_venue_product(symbol: "IRS-DE-BTCUSD-311221", contract_type: "interest_rate_swaps")
    ir_product = VenueAdapters.DeltaExchange.Product.build(ir_venue_product, @venue)
    assert ir_product.type == :swap

    spreads_venue_product = build_venue_product(symbol: "CS-BTCUSD-Mar-Dec", contract_type: "spreads")
    spreads_product = VenueAdapters.DeltaExchange.Product.build(spreads_venue_product, @venue)
    assert spreads_product.type == :swap
  end

  test ".build/2 can parse options products" do
    call_venue_product = build_venue_product(symbol: "C-BTC-64000-181121", contract_type: "call_options")
    call_product = VenueAdapters.DeltaExchange.Product.build(call_venue_product, @venue)
    assert call_product.type == :option

    put_venue_product = build_venue_product(symbol: "P-BTC-64000-181121", contract_type: "put_options")
    put_product = VenueAdapters.DeltaExchange.Product.build(put_venue_product, @venue)
    assert put_product.type == :option
  end

  test ".build/2 can parse move products" do
    venue_product = build_venue_product(symbol: "MV-BTC-60400-181121")
    product = VenueAdapters.DeltaExchange.Product.build(venue_product, @venue)

    assert product.type == :move
  end

  # test ".build/2 can parse listing" do
  #   venue_product = build_venue_product(symbol: "BTCUSD_31Dec", contract_type: "futures", launch_time: "2021-06-23T10:07:14Z")
  #   product = VenueAdapters.DeltaExchange.Product.build(venue_product, @venue)

  #   assert product.listing != nil
  # end

  @quoting_asset struct(ExDeltaExchange.Product.Asset, symbol: "USDT")
  @default_attrs [
    contract_unit_currency: "BTC",
    tick_size: "0.5",
    maker_commission_rate: "0.0005",
    taker_commission_rate: "0.0005",
    contract_value: "1",
    quoting_asset: @quoting_asset
  ]
  defp build_venue_product(attrs) do
    combined_attrs = Keyword.merge(@default_attrs, attrs)
    struct(ExDeltaExchange.Product, combined_attrs)
  end
end
