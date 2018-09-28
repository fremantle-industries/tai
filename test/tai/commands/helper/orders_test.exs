defmodule Tai.Commands.Helper.OrdersTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  setup do
    on_exit(fn ->
      Tai.TestSupport.Helpers.restart_application()
    end)
  end

  test "shows items in ascending order from when they were enqueued" do
    [btc_usd_order] =
      Tai.Trading.OrderStore.add(
        Tai.Trading.OrderSubmission.buy_limit(
          :test_exchange_a,
          :main,
          :btc_usd,
          12_999.99,
          1.1,
          Tai.Trading.TimeInForce.fill_or_kill()
        )
      )

    [ltc_usd_order] =
      Tai.Trading.OrderStore.add(
        Tai.Trading.OrderSubmission.sell_limit(
          :test_exchange_b,
          :main,
          :ltc_usd,
          75.23,
          1.0,
          Tai.Trading.TimeInForce.fill_or_kill()
        )
      )

    assert capture_io(&Tai.Commands.Helper.orders/0) == """
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

  test "shows an empty table when there are no orders" do
    assert capture_io(&Tai.Commands.Helper.orders/0) == """
           +----------+---------+--------+------+------+-------+------+---------------+--------+-----------+-----------+-------------+------------+--------------+
           | Exchange | Account | Symbol | Side | Type | Price | Size | Time in Force | Status | Client ID | Server ID | Enqueued At | Created At | Error Reason |
           +----------+---------+--------+------+------+-------+------+---------------+--------+-----------+-----------+-------------+------------+--------------+
           |        - |       - |      - |    - |    - |     - |    - |             - |      - |         - |         - |           - |          - |            - |
           +----------+---------+--------+------+------+-------+------+---------------+--------+-----------+-----------+-------------+------------+--------------+\n
           """
  end
end
