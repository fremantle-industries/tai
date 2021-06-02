defmodule Tai.IEx.Commands.NewOrderTest do
  use Tai.TestSupport.DataCase, async: false
  import ExUnit.CaptureIO
  import Mock

  defmodule DateTimeFactory do
    use Agent

    @date_times [
      DateTime.from_naive!(~N[2016-05-24 13:00:00.000000], "Etc/UTC"),
    ]

    def start_link(_) do
      Agent.start_link(fn -> 0 end, name: __MODULE__)
    end

    def utc_now() do
      call_count = Agent.get_and_update(__MODULE__, fn c -> {c, c + 1} end)
      Enum.at(@date_times, call_count)
    end
  end

  test "shows each attribute & value of the order as a row in the table" do
    start_supervised!(DateTimeFactory)

    with_mock Tai.DateTime, timestamp: fn -> DateTimeFactory.utc_now() end do
      {:ok, order} = create_order()

      assert capture_io(fn -> Tai.IEx.new_order(order.client_id) end) == """
        +----------------------+--------------------------------------+
        |            Attribute |                                Value |
        +----------------------+--------------------------------------+
        |            client_id | #{order.client_id} |
        |       venue_order_id | #{order.venue_order_id} |
        |               status |                             enqueued |
        |       product_symbol |                              btc_usd |
        | venue_product_symbol |                              BTC-USD |
        |                 side |                                  buy |
        |                price |                              10200.1 |
        |                  qty |                                  2.1 |
        |           leaves_qty |                                  2.1 |
        |       cumulative_qty |                                    0 |
        |            post_only |                                 true |
        |                close |                                false |
        +----------------------+--------------------------------------+\n
        """
    end
  end

  test "shows an empty table when the order can't be found" do
    client_id = Ecto.UUID.generate()
    assert capture_io(fn -> Tai.IEx.new_order(client_id) end) == """
           +-----------+-------+
           | Attribute | Value |
           +-----------+-------+
           |         - |     - |
           +-----------+-------+\n
           """
  end
end
