defmodule Examples.Advisors.CreateAndCancelPendingOrder.AdvisorTest do
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
      Examples.Advisors.CreateAndCancelPendingOrder.Advisor,
      [
        group_id: :create_and_cancel_pending_order,
        advisor_id: :btc_usd,
        order_books: %{test_exchange_a: [:btc_usd]},
        store: %{}
      ]
    })

    :ok
  end

  test "creates a single pending limit order and then cancels it" do
    Tai.TestSupport.Mocks.Orders.GoodTillCancel.unfilled(
      server_id: "orderA",
      symbol: :btc_usd,
      price: Decimal.new(100.1),
      original_size: Decimal.new(0.1)
    )

    Tai.TestSupport.Mocks.Orders.GoodTillCancel.canceled(server_id: "orderA")

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
             ~r/\[order:.{36,36},pending,test_exchange_a,main,btc_usd,buy,limit,gtc,100.1,0.1,\]/

    assert log_msg =~
             ~r/\[order:.{36,36},canceling,test_exchange_a,main,btc_usd,buy,limit,gtc,100.1,0.1,\]/

    assert log_msg =~
             ~r/\[order:.{36,36},canceled,test_exchange_a,main,btc_usd,buy,limit,gtc,100.1,0.1,\]/
  end
end
