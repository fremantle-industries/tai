defmodule Tai.VenuesAdapters.Bitmex.ProductTest do
  use ExUnit.Case, async: false

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tzdata)
    end)

    {:ok, _} = Application.ensure_all_started(:tzdata)
    :ok
  end

  describe ".build/2" do
    @base_attrs %{
      symbol: "XBTUSD",
      underlying: "XBT",
      quote_currency: "USD",
      state: "Open",
      lot_size: 1,
      tick_size: 0.5,
      typ: "FFWCSX"
    }

    test "returns a product struct from a venue instrument" do
      instrument = struct(ExBitmex.Instrument, @base_attrs)

      product = Tai.VenueAdapters.Bitmex.Product.build(instrument, :venue_a)
      assert product.venue_id == :venue_a
      assert product.symbol == :xbtusd
      assert product.venue_symbol == "XBTUSD"
      assert product.status == :trading
      assert product.type == :swap
      assert product.price_increment == Decimal.new("0.5")
      assert product.min_price == Decimal.new("0.5")
      assert product.size_increment == Decimal.new(1)
      assert product.value == Decimal.new(1)
    end

    test "assigns maker/taker fee when present" do
      attrs = Map.merge(@base_attrs, %{maker_fee: "-0.025", taker_fee: "0.05"})
      instrument = struct(ExBitmex.Instrument, attrs)

      product = Tai.VenueAdapters.Bitmex.Product.build(instrument, :venue_a)
      assert product.venue_id == :venue_a
      assert product.symbol == :xbtusd
      assert product.maker_fee == Decimal.new("-0.025")
      assert product.taker_fee == Decimal.new("0.05")
    end

    test "assigns max size when present" do
      attrs = Map.merge(@base_attrs, %{max_order_qty: 100})
      instrument = struct(ExBitmex.Instrument, attrs)

      product = Tai.VenueAdapters.Bitmex.Product.build(instrument, :venue_a)
      assert product.venue_id == :venue_a
      assert product.symbol == :xbtusd
      assert product.max_size == Decimal.new(100)
    end

    test "assigns max price when present" do
      attrs = Map.merge(@base_attrs, %{max_price: 100_000})
      instrument = struct(ExBitmex.Instrument, attrs)

      product = Tai.VenueAdapters.Bitmex.Product.build(instrument, :venue_a)
      assert product.venue_id == :venue_a
      assert product.symbol == :xbtusd
      assert product.max_price == Decimal.new(100_000)
    end

    test "assigns listing & expiry when present" do
      attrs =
        Map.merge(@base_attrs, %{
          listing: "2019-12-13T06:00:00.000Z",
          expiry: "2020-03-27T12:00:00.000Z"
        })

      instrument = struct(ExBitmex.Instrument, attrs)

      product = Tai.VenueAdapters.Bitmex.Product.build(instrument, :venue_a)
      assert product.venue_id == :venue_a
      assert product.symbol == :xbtusd
      assert %DateTime{} = product.listing
      assert %DateTime{} = product.expiry
    end

    test "returns nil when instrument lot_size is nil" do
      instrument = struct(ExBitmex.Instrument, lot_size: nil)

      assert Tai.VenueAdapters.Bitmex.Product.build(instrument, :venue_a) == nil
    end
  end
end
