require IEx

defmodule Tai.Commands.HelperTest do
  use ExUnit.Case
  doctest Tai.Commands.Helper

  import ExUnit.CaptureIO
  import Tai.TestSupport.Helpers
  import Tai.TestSupport.Mock

  alias Tai.{Commands.Helper, Markets.OrderBook}
  alias Tai.Trading.{OrderSubmission, TimeInForce}

  setup do
    on_exit(fn ->
      restart_application()
    end)

    test_feed_a_btc_usd = [feed_id: :test_feed_a, symbol: :btc_usd] |> OrderBook.to_name()
    stop_supervised(test_feed_a_btc_usd)
    start_supervised!(Tai.TestSupport.Mocks.Server)

    {:ok, %{test_feed_a_btc_usd: test_feed_a_btc_usd}}
  end

  test "help returns the usage for the supported commands" do
    assert capture_io(&Helper.help/0) == """
           * balance
           * products
           * fees
           * markets
           * orders
           * buy_limit exchange_id(:gdax), account_id(:main), symbol(:btc_usd), price(101.12), size(1.2)
           * sell_limit exchange_id(:gdax), account_id(:main), symbol(:btc_usd), price(101.12), size(1.2)
           * settings
           * enable_send_orders
           * disable_send_orders\n
           """
  end

  test "products shows the list of products and their trade restrictions for the configured exchanges" do
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

    assert capture_io(&Helper.products/0) == """
           +-----------------+---------+-----------------+---------+-----------+-----------+-----------------+----------+----------+----------------+--------------+
           |     Exchange ID |  Symbol | Exchange Symbol |  Status | Min Price | Max Price | Price Increment | Min Size | Max Size | Size Increment | Min Notional |
           +-----------------+---------+-----------------+---------+-----------+-----------+-----------------+----------+----------+----------------+--------------+
           | test_exchange_a | btc_usd |         BTC_USD | trading |   0.00001 |    100000 |        0.000001 |    0.001 |   100000 |          0.001 |         0.01 |
           | test_exchange_b | eth_usd |         ETH_USD | trading |   0.00001 |    100000 |        0.000001 |    0.001 |          |          0.001 |         0.01 |
           +-----------------+---------+-----------------+---------+-----------+-----------+-----------------+----------+----------+----------------+--------------+\n
           """
  end

  test "fees shows the accounts maker/taker fees for every product on each exchange" do
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

    assert capture_io(&Helper.fees/0) == """
           +-----------------+------------+---------+--------+-------+
           |     Exchange ID | Account ID |  Symbol |  Maker | Taker |
           +-----------------+------------+---------+--------+-------+
           | test_exchange_a |       main | btc_usd | -0.05% |  0.2% |
           | test_exchange_b |       main | eth_usd |     0% |  0.1% |
           +-----------------+------------+---------+--------+-------+\n
           """
  end

  test "balance shows the symbols on each exchange with a non-zero balance" do
    mock_asset_balance(:test_exchange_a, :main, :btc, 0.1, 1.81227740)

    mock_asset_balance(
      :test_exchange_a,
      :main,
      :eth,
      "0.000000000000000000",
      "0.000000000000200000"
    )

    mock_asset_balance(:test_exchange_a, :main, :ltc, "0.00000000", "0.03000000")

    mock_asset_balance(:test_exchange_b, :main, :btc, 0.1, 1.81227740)

    mock_asset_balance(
      :test_exchange_b,
      :main,
      :eth,
      "0.000000000000000000",
      "0.000000000000200000"
    )

    mock_asset_balance(:test_exchange_b, :main, :ltc, "0.00000000", "0.03000000")

    assert capture_io(fn -> Helper.balance() end) == """
           +-----------------+---------+--------+----------------------+----------------------+----------------------+
           |        Exchange | Account | Symbol |                 Free |               Locked |              Balance |
           +-----------------+---------+--------+----------------------+----------------------+----------------------+
           | test_exchange_a |    main |    btc |           0.10000000 |           1.81227740 |           1.91227740 |
           | test_exchange_a |    main |    eth | 0.000000000000000000 | 0.000000000000200000 | 0.000000000000200000 |
           | test_exchange_a |    main |    ltc |           0.00000000 |           0.03000000 |           0.03000000 |
           | test_exchange_b |    main |    btc |           0.10000000 |           1.81227740 |           1.91227740 |
           | test_exchange_b |    main |    eth | 0.000000000000000000 | 0.000000000000200000 | 0.000000000000200000 |
           | test_exchange_b |    main |    ltc |           0.00000000 |           0.03000000 |           0.03000000 |
           +-----------------+---------+--------+----------------------+----------------------+----------------------+\n
           """
  end

  test("markets displays all inside quotes and the time they were last processed and changed", %{
    test_feed_a_btc_usd: test_feed_a_btc_usd
  }) do
    :ok =
      OrderBook.replace(test_feed_a_btc_usd, %OrderBook{
        bids: %{
          12_999.99 => {0.000021, Timex.now(), Timex.now()},
          12_999.98 => {1.0, nil, nil}
        },
        asks: %{
          13_000.01 => {1.11, Timex.now(), Timex.now()},
          13_000.02 => {1.25, nil, nil}
        }
      })

    assert capture_io(fn -> Helper.markets() end) == """
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

  test "orders displays items in ascending order from when they were enqueued" do
    assert capture_io(fn -> Helper.orders() end) == """
           +----------+---------+--------+------+------+-------+------+---------------+--------+-----------+-----------+-------------+------------+--------------+
           | Exchange | Account | Symbol | Side | Type | Price | Size | Time in Force | Status | Client ID | Server ID | Enqueued At | Created At | Error Reason |
           +----------+---------+--------+------+------+-------+------+---------------+--------+-----------+-----------+-------------+------------+--------------+
           |        - |       - |      - |    - |    - |     - |    - |             - |      - |         - |         - |           - |          - |            - |
           +----------+---------+--------+------+------+-------+------+---------------+--------+-----------+-----------+-------------+------------+--------------+\n
           """

    [btc_usd_order] =
      Tai.Trading.OrderStore.add(
        OrderSubmission.buy_limit(
          :test_exchange_a,
          :main,
          :btc_usd,
          12_999.99,
          1.1,
          TimeInForce.fill_or_kill()
        )
      )

    [ltc_usd_order] =
      Tai.Trading.OrderStore.add(
        OrderSubmission.sell_limit(
          :test_exchange_b,
          :main,
          :ltc_usd,
          75.23,
          1.0,
          TimeInForce.fill_or_kill()
        )
      )

    assert capture_io(fn -> Helper.orders() end) == """
           +-----------------+---------+---------+------+-------+----------+------+---------------+----------+--------------------------------------+-----------+-------------+------------+--------------+
           |        Exchange | Account |  Symbol | Side |  Type |    Price | Size | Time in Force |   Status |                            Client ID | Server ID | Enqueued At | Created At | Error Reason |
           +-----------------+---------+---------+------+-------+----------+------+---------------+----------+--------------------------------------+-----------+-------------+------------+--------------+
           | test_exchange_a |    main | btc_usd |  buy | limit | 12999.99 |  1.1 |           fok | enqueued | #{
             btc_usd_order.client_id
           } |           |         now |            |              |
           | test_exchange_b |    main | ltc_usd | sell | limit |    75.23 |  1.0 |           fok | enqueued | #{
             ltc_usd_order.client_id
           } |           |         now |            |              |
           +-----------------+---------+---------+------+-------+----------+------+---------------+----------+--------------------------------------+-----------+-------------+------------+--------------+\n
           """
  end

  test "buy_limit enqueues an order and displays it's client id" do
    assert capture_io(fn ->
             Helper.buy_limit(
               :test_exchange_a,
               :main,
               :btc_usd_success,
               10.1,
               2.2,
               Tai.Trading.TimeInForce.fill_or_kill()
             )
           end) =~ "order enqueued. client_id:"
  end

  test "sell_limit enqueues an order and displays it's client id" do
    assert capture_io(fn ->
             Helper.sell_limit(
               :test_exchange_a,
               :main,
               :btc_usd_success,
               10.1,
               2.2,
               Tai.Trading.TimeInForce.fill_or_kill()
             )
           end) =~ "order enqueued. client_id:"
  end

  test "settings displays the current values" do
    assert capture_io(fn -> Helper.settings() end) == """
           +-------------+-------+
           |        Name | Value |
           +-------------+-------+
           | send_orders |  true |
           +-------------+-------+\n
           """
  end

  test "disable_send_orders sets the value to false" do
    assert capture_io(fn -> Helper.disable_send_orders() end) == """
           +-------------+-------+
           |        Name | Value |
           +-------------+-------+
           | send_orders | false |
           +-------------+-------+\n
           """
  end

  test "enable_send_orders sets the value to false" do
    Tai.Settings.disable_send_orders!()

    assert capture_io(fn -> Helper.enable_send_orders() end) == """
           +-------------+-------+
           |        Name | Value |
           +-------------+-------+
           | send_orders |  true |
           +-------------+-------+\n
           """
  end
end
