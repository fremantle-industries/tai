require IEx

defmodule Tai.Commands.HelperTest do
  use ExUnit.Case
  doctest Tai.Commands.Helper

  import ExUnit.CaptureIO
  import Tai.TestSupport.Mock

  alias Tai.{Commands.Helper, Markets.OrderBook}
  alias Tai.Trading.{OrderSubmission, TimeInForce}

  setup do
    test_feed_a_btc_usd = [feed_id: :test_feed_a, symbol: :btc_usd] |> OrderBook.to_name()
    stop_supervised(test_feed_a_btc_usd)

    on_exit(fn ->
      restart_application()
    end)

    {:ok, %{test_feed_a_btc_usd: test_feed_a_btc_usd}}
  end

  test "help returns the usage for the supported commands" do
    assert capture_io(&Helper.help/0) == """
           * balance
           * products
           * markets
           * orders
           * buy_limit exchange_id(:gdax), account_id(:main), symbol(:btc_usd), price(101.12), size(1.2)
           * sell_limit exchange_id(:gdax), account_id(:main), symbol(:btc_usd), price(101.12), size(1.2)
           * order_status exchange_id(:gdax), account_id(:main), order_id("f1bb2fa3-6218-45be-8691-21b98157f25a")
           * cancel_order exchange_id(:gdax), account_id(:main), order_id("f1bb2fa3-6218-45be-8691-21b98157f25a")\n
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
      max_size: Decimal.new("100000.00000000"),
      size_increment: Decimal.new("0.00100000"),
      min_notional: Decimal.new("0.01000000")
    })

    assert capture_io(&Helper.products/0) == """
           +-----------------+---------+-----------------+---------+------------+-----------------+-----------------+------------+-----------------+----------------+--------------+
           |     Exchange ID |  Symbol | Exchange Symbol |  Status |  Min Price |       Max Price | Price Increment |   Min Size |        Max Size | Size Increment | Min Notional |
           +-----------------+---------+-----------------+---------+------------+-----------------+-----------------+------------+-----------------+----------------+--------------+
           | test_exchange_a | btc_usd |         BTC_USD | trading | 0.00001000 | 100000.00000000 |      0.00000100 | 0.00100000 | 100000.00000000 |     0.00100000 |   0.01000000 |
           | test_exchange_b | eth_usd |         ETH_USD | trading | 0.00001000 | 100000.00000000 |      0.00000100 | 0.00100000 | 100000.00000000 |     0.00100000 |   0.01000000 |
           +-----------------+---------+-----------------+---------+------------+-----------------+-----------------+------------+-----------------+----------------+--------------+\n
           """
  end

  test "balance shows the symbols on each exchange with a non-zero balance" do
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
           +----------+---------+--------+------+------+-------+------+---------------+--------+-----------+-----------+-------------+------------+
           | Exchange | Account | Symbol | Side | Type | Price | Size | Time in Force | Status | Client ID | Server ID | Enqueued At | Created At |
           +----------+---------+--------+------+------+-------+------+---------------+--------+-----------+-----------+-------------+------------+
           |        - |       - |      - |    - |    - |     - |    - |             - |      - |         - |         - |           - |          - |
           +----------+---------+--------+------+------+-------+------+---------------+--------+-----------+-----------+-------------+------------+\n
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
           +-----------------+---------+---------+------+-------+----------+------+---------------+----------+--------------------------------------+-----------+-------------+------------+
           |        Exchange | Account |  Symbol | Side |  Type |    Price | Size | Time in Force |   Status |                            Client ID | Server ID | Enqueued At | Created At |
           +-----------------+---------+---------+------+-------+----------+------+---------------+----------+--------------------------------------+-----------+-------------+------------+
           | test_exchange_a |    main | btc_usd |  buy | limit | 12999.99 |  1.1 |           fok | enqueued | #{
             btc_usd_order.client_id
           } |           |         now |            |
           | test_exchange_b |    main | ltc_usd | sell | limit |    75.23 |  1.0 |           fok | enqueued | #{
             ltc_usd_order.client_id
           } |           |         now |            |
           +-----------------+---------+---------+------+-------+----------+------+---------------+----------+--------------------------------------+-----------+-------------+------------+\n
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

  test "order_status displays the order info" do
    assert capture_io(fn ->
             Helper.order_status(:test_exchange_a, :main, "f9df7435-34d5-4861-8ddc-80f0fd2c83d7")
           end) == "status: open\n"
  end

  test "order_status displays error messages" do
    assert capture_io(fn ->
             Helper.order_status(:test_exchange_a, :main, "invalid-order-id")
           end) == "error: Invalid order id\n"
  end

  test "cancel_order cancels a previous order" do
    assert capture_io(fn ->
             Helper.cancel_order(:test_exchange_a, :main, "f9df7435-34d5-4861-8ddc-80f0fd2c83d7")
           end) == "cancel order success\n"
  end

  test "cancel_order displays error messages" do
    assert capture_io(fn ->
             Helper.cancel_order(:test_exchange_a, :main, "invalid-order-id")
           end) == "error: Invalid order id\n"
  end
end
