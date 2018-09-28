defmodule Tai.Commands.Helper.FeesTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO
  import Tai.TestSupport.Mock

  setup do
    on_exit(fn ->
      Tai.TestSupport.Helpers.restart_application()
    end)
  end

  test "show the accounts maker/taker fees for every product on each exchange" do
    mock_fee_info(%{
      exchange_id: :test_exchange_a,
      account_id: :main,
      symbol: :btc_usd,
      maker: Decimal.new(-0.0005),
      maker_type: Tai.Exchanges.FeeInfo.percent(),
      taker: Decimal.new(0.002),
      taker_type: Tai.Exchanges.FeeInfo.percent()
    })

    mock_fee_info(%{
      exchange_id: :test_exchange_b,
      account_id: :main,
      symbol: :eth_usd,
      maker: Decimal.new(0),
      maker_type: Tai.Exchanges.FeeInfo.percent(),
      taker: Decimal.new(0.001),
      taker_type: Tai.Exchanges.FeeInfo.percent()
    })

    assert capture_io(&Tai.Commands.Helper.fees/0) == """
           +-----------------+------------+---------+--------+-------+
           |     Exchange ID | Account ID |  Symbol |  Maker | Taker |
           +-----------------+------------+---------+--------+-------+
           | test_exchange_a |       main | btc_usd | -0.05% |  0.2% |
           | test_exchange_b |       main | eth_usd |     0% |  0.1% |
           +-----------------+------------+---------+--------+-------+\n
           """
  end
end
