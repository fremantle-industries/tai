defmodule Tai.IEx.Commands.FailedOrderTransitionsTest do
  use Tai.TestSupport.DataCase, async: false
  import ExUnit.CaptureIO
  import Mock

  defmodule DateTimeFactory do
    use Agent

    @date_times [
      DateTime.from_naive!(~N[2016-05-24 13:00:00.000000], "Etc/UTC"),
      DateTime.from_naive!(~N[2016-05-24 13:00:01.000000], "Etc/UTC"),
    ]

    def start_link(_) do
      Agent.start_link(fn -> 0 end, name: __MODULE__)
    end

    def utc_now() do
      call_count = Agent.get_and_update(__MODULE__, fn c -> {c, c + 1} end)
      Enum.at(@date_times, call_count)
    end
  end

  test "displays failed order transitions in the order they were created" do
    start_supervised!(DateTimeFactory)

    with_mock Tai.DateTime, timestamp: fn -> DateTimeFactory.utc_now() end do
      {:ok, order} = create_order()
      {:ok, _transition} = create_failed_order_transition(order.client_id, :invalid, "accept_create")
      display_client_id = "#{order.client_id |> String.slice(0..5)}..."

      assert capture_io(fn -> Tai.IEx.failed_order_transitions(order.client_id) end) == """
        +-----------+-----------------------------+---------------+
        | Client ID |                  Created At |          Type |
        +-----------+-----------------------------+---------------+
        | #{display_client_id} | 2016-05-24 13:00:01.000000Z | accept_create |
        +-----------+-----------------------------+---------------+\n
        """
    end
  end

  test "shows an empty table when there are no order transitions" do
    client_id = Ecto.UUID.generate()
    assert capture_io(fn -> Tai.IEx.failed_order_transitions(client_id) end) == """
           +-----------+------------+------+
           | Client ID | Created At | Type |
           +-----------+------------+------+
           |         - |          - |    - |
           +-----------+------------+------+\n
           """
  end
end
