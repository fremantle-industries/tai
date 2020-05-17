defmodule Tai.VenuesAdapters.Deribit.ProductTest do
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
      instrument_name: "BTC-25SEP20",
      base_currency: "BTC",
      quote_currency: "USD",
      is_active: true,
      kind: "future",
      creation_timestamp: 1_588_838_404_000,
      expiration_timestamp: 1_590_134_400_000,
      min_trade_amount: 0.1,
      tick_size: 0.005,
      contract_size: 10.0,
      maker_commission: 0.004,
      taker_commission: 0.004
    }

    test "returns a product struct from a venue instrument" do
      instrument = struct(ExDeribit.Instrument, @base_attrs)

      product = Tai.VenueAdapters.Deribit.Product.build(instrument, :venue_a)
      assert product.venue_id == :venue_a
      assert product.symbol == :btc_25sep20
      assert product.venue_symbol == "BTC-25SEP20"
      assert product.status == :trading
      assert product.price_increment == Decimal.new("0.005")
      assert product.min_price == Decimal.new("0.005")
      assert product.size_increment == Decimal.new("0.1")
      assert product.value == Decimal.new("1E+1")
      assert product.is_quanto == false
      assert product.is_inverse == true
      assert %DateTime{} = product.listing
      assert %DateTime{} = product.expiry
    end

    test "type is :option when kind is 'option'" do
      attrs = Map.merge(@base_attrs, %{kind: "option"})
      instrument = struct(ExDeribit.Instrument, attrs)

      product = Tai.VenueAdapters.Deribit.Product.build(instrument, :venue_a)
      assert product.type == :option
    end

    test "type is :swap when kind is 'future' & instrument name includes 'PERPETUAL'" do
      attrs = Map.merge(@base_attrs, %{kind: "future", instrument_name: "BTC-PERPETUAL"})
      instrument = struct(ExDeribit.Instrument, attrs)

      product = Tai.VenueAdapters.Deribit.Product.build(instrument, :venue_a)
      assert product.type == :swap
    end

    test "assigns maker/taker fee" do
      attrs = Map.merge(@base_attrs, %{maker_commission: "-0.025", taker_commission: "0.05"})
      instrument = struct(ExDeribit.Instrument, attrs)

      product = Tai.VenueAdapters.Deribit.Product.build(instrument, :venue_a)
      assert product.venue_id == :venue_a
      assert product.maker_fee == Decimal.new("-0.025")
      assert product.taker_fee == Decimal.new("0.05")
    end

    test "assigns the option_type" do
      call_attrs = Map.merge(@base_attrs, %{option_type: "call"})
      call_instrument = struct(ExDeribit.Instrument, call_attrs)
      product = Tai.VenueAdapters.Deribit.Product.build(call_instrument, :venue_a)
      assert product.option_type == :call

      put_attrs = Map.merge(@base_attrs, %{option_type: "put"})
      put_instrument = struct(ExDeribit.Instrument, put_attrs)
      product = Tai.VenueAdapters.Deribit.Product.build(put_instrument, :venue_a)
      assert product.option_type == :put
    end

    test "assigns the strike price as a normal reduced decimal " do
      attrs = Map.merge(@base_attrs, %{strike: 10_000.0})
      instrument = struct(ExDeribit.Instrument, attrs)

      product = Tai.VenueAdapters.Deribit.Product.build(instrument, :venue_a)
      assert product.strike == Decimal.new("10000")
    end
  end
end
