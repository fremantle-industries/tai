defmodule Examples.Advisors.FillOrKillOrders.AdvisorTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  import Tai.TestSupport.Mock

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    start_supervised!(Tai.TestSupport.Mocks.Server)
    Tai.Settings.enable_send_orders!()

    start_supervised!({
      Examples.Advisors.FillOrKillOrders.Advisor,
      [
        group_id: :fill_or_kill_orders,
        advisor_id: :btc_usd,
        order_books: %{test_exchange_a: [:btc_usd]},
        store: %{}
      ]
    })

    :ok
  end

  test "creates a single fill or kill order" do
    Tai.TestSupport.Mocks.Orders.FillOrKill.filled(
      symbol: :btc_usd,
      price: Decimal.new(100.1),
      original_size: Decimal.new(0.1)
    )

    log_msg =
      capture_log(fn ->
        mock_snapshot(
          :test_exchange_a,
          :btc_usd,
          %{100.1 => 1.1},
          %{100.11 => 1.2}
        )

        :timer.sleep(100)
      end)

    assert log_msg =~
             ~r/\[order:.{36,36},enqueued,test_exchange_a,main,btc_usd,buy,limit,fok,100.1,0.1,\]/

    assert log_msg =~ ~r/filled order %Tai.Trading.Order{/
  end
end
