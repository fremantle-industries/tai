defmodule Tai.VenuesAdapters.Bybit.ProductTest do
  use ExUnit.Case, async: false
  alias ExBybit.Derivatives

  @base_derivative_attrs %{
    name: "BTCUSD",
    base_currency: "BTC",
    quote_currency: "USD",
    status: "Trading",
    price_filter: %Derivatives.Symbol.PriceFilter{
      tick_size: "0.5",
      min_price: "0.5",
      max_price: "999999.5"
    },
    lot_size_filter: %Derivatives.Symbol.LotSizeFilter{
      qty_step: 1,
      min_trading_qty: 1,
      max_trading_qty: 1_000_000
    }
  }

  describe ".build/2" do
    test "returns a product struct from a venue derivative symbol" do
      derivative_symbol = struct(Derivatives.Symbol, @base_derivative_attrs)

      product = build(derivative_symbol, :venue_a)
      assert product.venue_id == :venue_a
      assert product.symbol == :btcusd
      assert product.venue_symbol == "BTCUSD"
      assert product.base == :btc
      assert product.quote == :usd
      assert product.venue_base == "BTC"
      assert product.venue_quote == "USD"
      assert product.status == :trading
      assert product.price_increment == Decimal.new("0.5")
      assert product.min_price == Decimal.new("0.5")
      assert product.size_increment == Decimal.new("1")
      assert product.min_size == Decimal.new("1")
      assert product.value == Decimal.new("1")
      assert product.value_side == :quote
      assert product.type != nil
      assert product.is_inverse != nil
    end

    test "sets type to :future when it ends with digits and :swap otherwise" do
      future_derivative_attrs = Map.merge(@base_derivative_attrs, %{name: "BTCUSDZ21", alias: "BTCUSD1231"})
      future_derivative_symbol = struct(Derivatives.Symbol, future_derivative_attrs)
      future_product = build(future_derivative_symbol, :venue_a)
      assert future_product.type == :future

      swap_derivative_attrs = Map.merge(@base_derivative_attrs, %{name: "BTCUSD"})
      swap_derivative_symbol = struct(Derivatives.Symbol, swap_derivative_attrs)
      swap_product = build(swap_derivative_symbol, :venue_a)
      assert swap_product.type == :swap
    end

    test "sets is_inverse to true for futures and swaps with USD quote currency" do
      future_derivative_attrs = Map.merge(@base_derivative_attrs, %{name: "BTCUSDZ21", alias: "BTCUSD1231"})
      future_derivative_symbol = struct(Derivatives.Symbol, future_derivative_attrs)
      future_product = build(future_derivative_symbol, :venue_a)
      assert future_product.is_inverse == true

      inverse_swap_derivative_attrs = Map.merge(@base_derivative_attrs, %{name: "BTCUSD", quote_currency: "USD"})
      inverse_swap_derivative_symbol = struct(Derivatives.Symbol, inverse_swap_derivative_attrs)
      inverse_swap_product = build(inverse_swap_derivative_symbol, :venue_a)
      assert inverse_swap_product.is_inverse == true

      linear_swap_derivative_attrs = Map.merge(@base_derivative_attrs, %{name: "BTCUSDT", quote_currency: "USDT"})
      linear_swap_derivative_symbol = struct(Derivatives.Symbol, linear_swap_derivative_attrs)
      linear_swap_product = build(linear_swap_derivative_symbol, :venue_a)
      assert linear_swap_product.is_inverse == false
    end

    test "sets expiry for futures" do
      future_derivative_attrs = Map.merge(@base_derivative_attrs, %{name: "BTCUSDZ21", alias: "BTCUSD1231"})
      future_derivative_symbol = struct(Derivatives.Symbol, future_derivative_attrs)
      future_product = build(future_derivative_symbol, :venue_a)
      assert future_product.expiry == ~U[2021-12-31 08:00:00.000000Z]

      swap_derivative_attrs = Map.merge(@base_derivative_attrs, %{name: "BTCUSD"})
      swap_derivative_symbol = struct(Derivatives.Symbol, swap_derivative_attrs)
      swap_product = build(swap_derivative_symbol, :venue_a)
      assert swap_product.expiry == nil
    end
  end

  defp build(struct, venue) do
    Tai.VenueAdapters.Bybit.Product.build(struct, venue)
  end
end
