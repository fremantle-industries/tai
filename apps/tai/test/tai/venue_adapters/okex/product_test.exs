defmodule Tai.VenuesAdapters.OkEx.ProductTest do
  use ExUnit.Case, async: false

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tzdata)
    end)

    {:ok, _} = Application.ensure_all_started(:tzdata)
    :ok
  end

  describe ".build/2" do
    test "returns a product struct from a venue futures instrument" do
      attrs = %{
        instrument_id: "BTC-USDT-200327",
        base_currency: "BTC",
        quote_currency: "USDT",
        trade_increment: "1",
        tick_size: "0.01",
        contract_val: "100",
        listing: "2019-12-13",
        delivery: "2020-03-27"
      }

      instrument = struct(ExOkex.Futures.Instrument, attrs)

      product = Tai.VenueAdapters.OkEx.Product.build(instrument, :venue_a)
      assert product.venue_id == :venue_a
      assert product.symbol == :btc_usdt_200327
      assert product.venue_symbol == "BTC-USDT-200327"
      assert product.base == :btc
      assert product.quote == :usdt
      assert product.venue_base == "BTC"
      assert product.venue_quote == "USDT"
      assert product.status == :trading
      assert product.price_increment == Decimal.new("0.01")
      assert product.min_price == Decimal.new("0.01")
      assert product.size_increment == Decimal.new("1")
      assert product.min_size == Decimal.new("1")
      assert product.value == Decimal.new("100")
      assert %DateTime{} = product.listing
      assert %DateTime{} = product.expiry
      assert product.is_inverse == false
    end

    test "returns a product struct from a venue swap instrument" do
      attrs = %{
        instrument_id: "BTC-USDT-SWAP",
        base_currency: "BTC",
        quote_currency: "USDT",
        size_increment: "1",
        tick_size: "0.01",
        contract_val: "100",
        listing: "2019-11-12T11:16:48.000Z",
        delivery: "2020-01-04T08:00:00.000Z",
        is_inverse: "false"
      }

      instrument = struct(ExOkex.Swap.Instrument, attrs)

      product = Tai.VenueAdapters.OkEx.Product.build(instrument, :venue_a)
      assert product.venue_id == :venue_a
      assert product.symbol == :btc_usdt_swap
      assert product.venue_symbol == "BTC-USDT-SWAP"
      assert product.base == :btc
      assert product.quote == :usdt
      assert product.venue_base == "BTC"
      assert product.venue_quote == "USDT"
      assert product.status == :trading
      assert product.price_increment == Decimal.new("0.01")
      assert product.min_price == Decimal.new("0.01")
      assert product.size_increment == Decimal.new("1")
      assert product.min_size == Decimal.new("1")
      assert product.value == Decimal.new("100")
      assert %DateTime{} = product.listing
      assert product.expiry == nil
      assert product.is_inverse == false
    end

    test "returns a product struct from a venue spot instrument" do
      attrs = %{
        instrument_id: "BTC-USDT",
        base_currency: "BTC",
        quote_currency: "USDT",
        size_increment: "0.00000001",
        min_size: "0.001",
        tick_size: "0.1"
      }

      instrument = struct(ExOkex.Spot.Instrument, attrs)

      product = Tai.VenueAdapters.OkEx.Product.build(instrument, :venue_a)
      assert product.venue_id == :venue_a
      assert product.symbol == :btc_usdt
      assert product.venue_symbol == "BTC-USDT"
      assert product.base == :btc
      assert product.quote == :usdt
      assert product.venue_base == "BTC"
      assert product.venue_quote == "USDT"
      assert product.status == :trading
      assert product.price_increment == Decimal.new("0.1")
      assert product.min_price == Decimal.new("0.1")
      assert product.size_increment == Decimal.new("0.00000001")
      assert product.min_size == Decimal.new("0.001")
      assert product.value == Decimal.new(1)
      assert product.listing == nil
      assert product.expiry == nil
      assert product.is_inverse == false
    end

    test "futures products can be inverse" do
      attrs = %{
        instrument_id: "BTC-USD-200327",
        base_currency: "BTC",
        quote_currency: "USDT",
        trade_increment: "1",
        tick_size: "0.01",
        contract_val: "100",
        listing: "2019-12-13",
        delivery: "2020-03-27",
        is_inverse: "true"
      }

      instrument = struct(ExOkex.Futures.Instrument, attrs)

      product = Tai.VenueAdapters.OkEx.Product.build(instrument, :venue_a)
      assert product.venue_id == :venue_a
      assert product.symbol == :btc_usd_200327
      assert product.venue_symbol == "BTC-USD-200327"
      assert product.is_inverse == true
    end

    test "swap products can be inverse" do
      attrs = %{
        instrument_id: "BTC-USD-SWAP",
        base_currency: "BTC",
        quote_currency: "USDT",
        size_increment: "1",
        tick_size: "0.01",
        contract_val: "100",
        listing: "2019-11-12T11:16:48.000Z",
        delivery: "2020-01-04T08:00:00.000Z",
        is_inverse: "true"
      }

      instrument = struct(ExOkex.Swap.Instrument, attrs)

      product = Tai.VenueAdapters.OkEx.Product.build(instrument, :venue_a)
      assert product.venue_id == :venue_a
      assert product.symbol == :btc_usd_swap
      assert product.venue_symbol == "BTC-USD-SWAP"
      assert product.is_inverse == true
    end
  end
end
