defmodule Tai.IEx.Commands.EstimatedFundingRatesTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  import Tai.TestSupport.Mock

  setup do
    start_supervised!(Tai.Venues.EstimatedFundingRateStore)
    start_supervised!(Tai.Commander)
    :ok
  end

  test "show estimated funding rates for configured venues" do
    mock_estimated_funding_rate(
      next_time: Timex.parse!("2007-08-11T13:00:00", "{ISO:Extended}"),
      venue: :test_exchange_a,
      venue_product_symbol: "BTC-USD",
      product_symbol: :btc_usd,
      next_rate: Decimal.new("0.011")
    )

    mock_estimated_funding_rate(
      next_time: Timex.parse!("2010-08-11T13:00:00", "{ISO:Extended}"),
      venue: :test_exchange_b,
      venue_product_symbol: "ETH-USD",
      product_symbol: :eth_usd,
      next_rate: Decimal.new("0.015")
    )

    assert capture_io(&Tai.IEx.estimated_funding_rates/0) == """
           +---------------------+-----------------+---------+-----------+
           |           Next Time |           Venue |  Symbol | Next Rate |
           +---------------------+-----------------+---------+-----------+
           | 2007-08-11 13:00:00 | test_exchange_a | btc_usd |    0.011% |
           | 2010-08-11 13:00:00 | test_exchange_b | eth_usd |    0.015% |
           +---------------------+-----------------+---------+-----------+\n
           """
  end

  test "shows an empty table when there are no estimated funding rates" do
    assert capture_io(&Tai.IEx.estimated_funding_rates/0) == """
           +-----------+-------+--------+-----------+
           | Next Time | Venue | Symbol | Next Rate |
           +-----------+-------+--------+-----------+
           |         - |     - |      - |         - |
           +-----------+-------+--------+-----------+\n
           """
  end
end
