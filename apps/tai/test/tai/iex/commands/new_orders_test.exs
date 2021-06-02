defmodule Tai.IEx.Commands.NewOrdersTest do
  use Tai.TestSupport.DataCase, async: false
  import ExUnit.CaptureIO
  import Mock

  defmodule DateTimeFactory do
    use Agent

    @date_times [
      DateTime.from_naive!(~N[2016-05-24 13:00:00.000000], "Etc/UTC"),
      DateTime.from_naive!(~N[2017-08-02 08:22:00.999000], "Etc/UTC")
    ]

    def start_link(_) do
      Agent.start_link(fn -> 0 end, name: __MODULE__)
    end

    def utc_now() do
      call_count = Agent.get_and_update(__MODULE__, fn c -> {c, c + 1} end)
      Enum.at(@date_times, call_count)
    end
  end

  test "shows items in ascending order from when they were enqueued" do
    start_supervised!(DateTimeFactory)

    with_mock Tai.DateTime,
      timestamp: fn -> DateTimeFactory.utc_now() end do
      {:ok, btc_order} =
        insert_spot_order(%{
          venue_order_id: "abc123",
          venue: "test_exchange_a",
          credential: "main",
          venue_product_symbol: "BTC-USD",
          product_symbol: "btc_usd",
          side: "buy",
          price: Decimal.new("12999.99"),
          qty: Decimal.new("1.1"),
          leaves_qty: Decimal.new("1.1"),
          cumulative_qty: Decimal.new(0)
        })

      {:ok, ltc_order} =
        insert_spot_order(%{
          venue_order_id: "abc456",
          venue: "test_exchange_b",
          credential: "main",
          venue_product_symbol: "LTC-USD",
          product_symbol: "ltc_usd",
          side: "sell",
          price: Decimal.new("75.23"),
          qty: Decimal.new("1.2"),
          leaves_qty: Decimal.new("1.2"),
          cumulative_qty: Decimal.new(0)
        })

      btc_client_id = short_client_id(btc_order)
      ltc_client_id = short_client_id(ltc_order)

      assert capture_io(&Tai.IEx.new_orders/0) == """
             +-----------------+------------+----------------+--------------+------+-------+----------+-----+------------+----------------+---------------+----------+-----------+----------------+-----------------------------+
             |           Venue | Credential | Product Symbol | Product Type | Side |  Type |    Price | Qty | Leaves Qty | Cumulative Qty | Time in Force |   Status | Client ID | Venue Order ID |                  Updated At |
             +-----------------+------------+----------------+--------------+------+-------+----------+-----+------------+----------------+---------------+----------+-----------+----------------+-----------------------------+
             | test_exchange_a |       main |        btc_usd |         spot |  buy | limit | 12999.99 | 1.1 |        1.1 |              0 |           fok | enqueued | #{
               btc_client_id
             } |      abc123... | 2016-05-24 13:00:00.000000Z |
             | test_exchange_b |       main |        ltc_usd |         spot | sell | limit |    75.23 | 1.2 |        1.2 |              0 |           fok | enqueued | #{
               ltc_client_id
             } |      abc456... | 2017-08-02 08:22:00.999000Z |
             +-----------------+------------+----------------+--------------+------+-------+----------+-----+------------+----------------+---------------+----------+-----------+----------------+-----------------------------+\n
             """
    end
  end

  test "shows an empty table when there are no orders" do
    assert capture_io(&Tai.IEx.new_orders/0) == """
           +-------+------------+----------------+--------------+------+------+-------+-----+------------+----------------+---------------+--------+-----------+----------------+------------+
           | Venue | Credential | Product Symbol | Product Type | Side | Type | Price | Qty | Leaves Qty | Cumulative Qty | Time in Force | Status | Client ID | Venue Order ID | Updated At |
           +-------+------------+----------------+--------------+------+------+-------+-----+------------+----------------+---------------+--------+-----------+----------------+------------+
           |     - |          - |              - |            - |    - |    - |     - |   - |          - |              - |             - |      - |         - |              - |          - |
           +-------+------------+----------------+--------------+------+------+-------+-----+------------+----------------+---------------+--------+-----------+----------------+------------+\n
           """
  end

  @base_params %{
    type: "limit",
    product_type: :spot,
    status: "enqueued",
    time_in_force: "fok",
    post_only: true,
    close: false
  }
  defp insert_spot_order(params) do
    merged_params = Map.merge(@base_params, params)
    changeset = Tai.NewOrders.Order.changeset(%Tai.NewOrders.Order{}, merged_params)
    Tai.NewOrders.OrderRepo.insert(changeset)
  end

  defp short_client_id(order) do
    "#{order.client_id |> String.slice(0..5)}..."
  end
end
