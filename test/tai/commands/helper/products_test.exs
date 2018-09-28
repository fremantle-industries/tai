defmodule Tai.Commands.Helper.ProductsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO
  import Tai.TestSupport.Mock

  setup do
    on_exit(fn ->
      Tai.TestSupport.Helpers.restart_application()
    end)
  end

  test "show products and their trade restrictions for configured exchanges" do
    mock_product(%Tai.Exchanges.Product{
      exchange_id: :test_exchange_a,
      symbol: :btc_usd,
      exchange_symbol: "BTC_USD",
      status: :trading,
      min_price: Decimal.new("0.00001000"),
      max_price: Decimal.new("100000.00000000"),
      price_increment: Decimal.new("0.00000100"),
      min_size: Decimal.new("0.00100000"),
      max_size: Decimal.new("100000.00000000"),
      size_increment: Decimal.new("0.00100000"),
      min_notional: Decimal.new("0.01000000")
    })

    mock_product(%Tai.Exchanges.Product{
      exchange_id: :test_exchange_b,
      symbol: :eth_usd,
      exchange_symbol: "ETH_USD",
      status: :trading,
      min_price: Decimal.new("0.00001000"),
      max_price: Decimal.new("100000.00000000"),
      price_increment: Decimal.new("0.00000100"),
      min_size: Decimal.new("0.00100000"),
      max_size: nil,
      size_increment: Decimal.new("0.00100000"),
      min_notional: Decimal.new("0.01000000")
    })

    assert capture_io(&Tai.Commands.Helper.products/0) == """
           +-----------------+---------+-----------------+---------+-----------+-----------+-----------------+----------+----------+----------------+--------------+
           |     Exchange ID |  Symbol | Exchange Symbol |  Status | Min Price | Max Price | Price Increment | Min Size | Max Size | Size Increment | Min Notional |
           +-----------------+---------+-----------------+---------+-----------+-----------+-----------------+----------+----------+----------------+--------------+
           | test_exchange_a | btc_usd |         BTC_USD | trading |   0.00001 |    100000 |        0.000001 |    0.001 |   100000 |          0.001 |         0.01 |
           | test_exchange_b | eth_usd |         ETH_USD | trading |   0.00001 |    100000 |        0.000001 |    0.001 |          |          0.001 |         0.01 |
           +-----------------+---------+-----------------+---------+-----------+-----------+-----------------+----------+----------+----------------+--------------+\n
           """
  end

  test "shows an empty table when there are no products" do
    assert capture_io(&Tai.Commands.Helper.products/0) == """
           +-------------+--------+-----------------+--------+-----------+-----------+-----------------+----------+----------+----------------+--------------+
           | Exchange ID | Symbol | Exchange Symbol | Status | Min Price | Max Price | Price Increment | Min Size | Max Size | Size Increment | Min Notional |
           +-------------+--------+-----------------+--------+-----------+-----------+-----------------+----------+----------+----------------+--------------+
           |           - |      - |               - |      - |         - |         - |               - |        - |        - |              - |            - |
           +-------------+--------+-----------------+--------+-----------+-----------+-----------------+----------+----------+----------------+--------------+\n
           """
  end
end
