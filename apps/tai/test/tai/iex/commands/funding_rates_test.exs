defmodule Tai.IEx.Commands.FundingRatesTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  import Tai.TestSupport.Mock

  setup do
    start_supervised!(Tai.Venues.FundingRateStore)
    start_supervised!(Tai.Commander)
    :ok
  end

  test "show funding rates for configured venues" do
    mock_funding_rate(
      time: Timex.parse!("2007-08-11T13:00:00", "{ISO:Extended}"),
      venue: :test_exchange_a,
      venue_product_symbol: "BTC-USD",
      product_symbol: :btc_usd,
      rate: Decimal.new("0.01")
    )

    mock_funding_rate(
      time: Timex.parse!("2010-08-11T13:00:00", "{ISO:Extended}"),
      venue: :test_exchange_b,
      venue_product_symbol: "ETH-USD",
      product_symbol: :eth_usd,
      rate: Decimal.new("0.027")
    )

    assert capture_io(&Tai.IEx.funding_rates/0) == """
           +---------------------+-----------------+---------+--------+
           |                Time |           Venue |  Symbol |   Rate |
           +---------------------+-----------------+---------+--------+
           | 2007-08-11 13:00:00 | test_exchange_a | btc_usd |  0.01% |
           | 2010-08-11 13:00:00 | test_exchange_b | eth_usd | 0.027% |
           +---------------------+-----------------+---------+--------+\n
           """
  end

  test "shows an empty table when there are no funding rates" do
    assert capture_io(&Tai.IEx.funding_rates/0) == """
           +------+-------+--------+------+
           | Time | Venue | Symbol | Rate |
           +------+-------+--------+------+
           |    - |     - |      - |    - |
           +------+-------+--------+------+\n
           """
  end
end
