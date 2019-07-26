defmodule Tai.Commands.MarketsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    start_supervised!(Tai.TestSupport.Mocks.Server)
    mock_products()
    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  test "shows all inside quotes and the time they were last processed and changed" do
    :ok =
      %Tai.Markets.OrderBook{
        venue_id: :test_exchange_a,
        product_symbol: :btc_usd,
        bids: %{
          12_999.99 => {0.000021, Timex.now(), Timex.now()},
          12_999.98 => {1.0, nil, nil}
        },
        asks: %{
          13_000.01 => {1.11, Timex.now(), Timex.now()},
          13_000.02 => {1.25, nil, nil}
        }
      }
      |> Tai.Markets.OrderBook.replace()

    assert capture_io(&Tai.CommandsHelper.markets/0) == """
           +-----------------+---------+-----------+-----------+----------+----------+------------------+-----------------------+------------------+-----------------------+
           |           Venue | Product | Bid Price | Ask Price | Bid Size | Ask Size | Bid Processed At | Bid Server Changed At | Ask Processed At | Ask Server Changed At |
           +-----------------+---------+-----------+-----------+----------+----------+------------------+-----------------------+------------------+-----------------------+
           | test_exchange_a | btc_usd |  12999.99 |  13000.01 | 0.000021 |     1.11 |              now |                   now |              now |                   now |
           | test_exchange_a | ltc_usd |         ~ |         ~ |        ~ |        ~ |                ~ |                     ~ |                ~ |                     ~ |
           | test_exchange_b | eth_usd |         ~ |         ~ |        ~ |        ~ |                ~ |                     ~ |                ~ |                     ~ |
           | test_exchange_b | ltc_usd |         ~ |         ~ |        ~ |        ~ |                ~ |                     ~ |                ~ |                     ~ |
           +-----------------+---------+-----------+-----------+----------+----------+------------------+-----------------------+------------------+-----------------------+\n
           """
  end

  def mock_products() do
    Tai.TestSupport.Mocks.Responses.Products.for_venue(
      :test_exchange_a,
      [
        %{symbol: :btc_usd},
        %{symbol: :ltc_usd}
      ]
    )

    Tai.TestSupport.Mocks.Responses.Products.for_venue(
      :test_exchange_b,
      [
        %{symbol: :eth_usd},
        %{symbol: :ltc_usd}
      ]
    )
  end
end
