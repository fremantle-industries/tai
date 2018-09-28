defmodule Tai.Commands.Helper.MarketsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  setup do
    on_exit(fn ->
      Tai.TestSupport.Helpers.restart_application()
    end)
  end

  test "shows all inside quotes and the time they were last processed and changed" do
    :ok =
      [feed_id: :test_feed_a, symbol: :btc_usd]
      |> Tai.Markets.OrderBook.to_name()
      |> Tai.Markets.OrderBook.replace(%Tai.Markets.OrderBook{
        bids: %{
          12_999.99 => {0.000021, Timex.now(), Timex.now()},
          12_999.98 => {1.0, nil, nil}
        },
        asks: %{
          13_000.01 => {1.11, Timex.now(), Timex.now()},
          13_000.02 => {1.25, nil, nil}
        }
      })

    assert capture_io(&Tai.Commands.Helper.markets/0) == """
           +-------------+---------+-----------+-----------+----------+----------+------------------+-----------------------+------------------+-----------------------+
           |        Feed |  Symbol | Bid Price | Ask Price | Bid Size | Ask Size | Bid Processed At | Bid Server Changed At | Ask Processed At | Ask Server Changed At |
           +-------------+---------+-----------+-----------+----------+----------+------------------+-----------------------+------------------+-----------------------+
           | test_feed_a | btc_usd |  12999.99 |  13000.01 | 0.000021 |     1.11 |              now |                   now |              now |                   now |
           | test_feed_a | ltc_usd |         ~ |         ~ |        ~ |        ~ |                ~ |                     ~ |                ~ |                     ~ |
           | test_feed_b | eth_usd |         ~ |         ~ |        ~ |        ~ |                ~ |                     ~ |                ~ |                     ~ |
           | test_feed_b | ltc_usd |         ~ |         ~ |        ~ |        ~ |                ~ |                     ~ |                ~ |                     ~ |
           +-------------+---------+-----------+-----------+----------+----------+------------------+-----------------------+------------------+-----------------------+\n
           """
  end
end
