defmodule Tai.IEx.Commands.ProductsTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  import Tai.TestSupport.Mock

  setup do
    start_supervised!(Tai.Venues.ProductStore)
    start_supervised!(Tai.Commander)
    :ok
  end

  test "show products and their trade restrictions for configured exchanges" do
    mock_product(
      venue_id: :test_exchange_a,
      symbol: :btc_usd,
      venue_symbol: "BTC_USD",
      status: :trading,
      type: :spot,
      maker_fee: Decimal.new("0.001"),
      taker_fee: Decimal.new("0.002")
    )

    mock_product(
      venue_id: :test_exchange_b,
      symbol: :eth_usd,
      venue_symbol: "ETH_USD",
      status: :trading,
      type: :spot
    )

    assert capture_io(&Tai.IEx.products/0) == """
           +-----------------+---------+--------------+---------+------+-----------+-----------+
           |           Venue |  Symbol | Venue Symbol |  Status | Type | Maker Fee | Taker Fee |
           +-----------------+---------+--------------+---------+------+-----------+-----------+
           | test_exchange_a | btc_usd |      BTC_USD | trading | spot |      0.1% |      0.2% |
           | test_exchange_b | eth_usd |      ETH_USD | trading | spot |           |           |
           +-----------------+---------+--------------+---------+------+-----------+-----------+\n
           """
  end

  test "shows an empty table when there are no products" do
    assert capture_io(&Tai.IEx.products/0) == """
           +-------+--------+--------------+--------+------+-----------+-----------+
           | Venue | Symbol | Venue Symbol | Status | Type | Maker Fee | Taker Fee |
           +-------+--------+--------------+--------+------+-----------+-----------+
           |     - |      - |            - |      - |    - |         - |         - |
           +-------+--------+--------------+--------+------+-----------+-----------+\n
           """
  end
end
