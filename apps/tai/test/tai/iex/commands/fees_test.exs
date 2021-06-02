defmodule Tai.IEx.Commands.FeesTest do
  use Tai.TestSupport.DataCase, async: false
  import ExUnit.CaptureIO

  test "show the maker/taker fees for every product on each exchange" do
    mock_fee_info(%{
      venue_id: :test_exchange_a,
      credential_id: :main,
      symbol: :btc_usd,
      maker: Decimal.new("-0.0005"),
      maker_type: Tai.Venues.FeeInfo.percent(),
      taker: Decimal.new("0.002"),
      taker_type: Tai.Venues.FeeInfo.percent()
    })

    mock_fee_info(%{
      venue_id: :test_exchange_b,
      credential_id: :main,
      symbol: :eth_usd,
      maker: Decimal.new(0),
      maker_type: Tai.Venues.FeeInfo.percent(),
      taker: Decimal.new("0.001"),
      taker_type: Tai.Venues.FeeInfo.percent()
    })

    assert capture_io(&Tai.IEx.fees/0) == """
           +-----------------+------------+---------+--------+-------+
           |           Venue | Credential |  Symbol |  Maker | Taker |
           +-----------------+------------+---------+--------+-------+
           | test_exchange_a |       main | btc_usd | -0.05% |  0.2% |
           | test_exchange_b |       main | eth_usd |     0% |  0.1% |
           +-----------------+------------+---------+--------+-------+\n
           """
  end

  test "shows an empty table when there are no fees" do
    assert capture_io(&Tai.IEx.fees/0) == """
           +-------+------------+--------+-------+-------+
           | Venue | Credential | Symbol | Maker | Taker |
           +-------+------------+--------+-------+-------+
           |     - |          - |      - |     - |     - |
           +-------+------------+--------+-------+-------+\n
           """
  end
end
