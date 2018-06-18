defmodule Tai.Trading.OrderPipeline.SendTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  setup do
    on_exit(fn ->
      Tai.Trading.OrderStore.clear()
    end)

    test_pid = self()

    callback = fn previous_order, updated_order ->
      send(test_pid, {:callback_fired, previous_order, updated_order})
    end

    {:ok, callback: callback}
  end

  describe "fill or kill" do
    test "expires unfilled buy orders", %{callback: callback} do
      order =
        Tai.Trading.OrderPipeline.buy_limit(
          :test_account_a,
          :btc_usd_expired,
          100.1,
          0.1,
          :fok,
          callback
        )

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{status: :enqueued} = previous_order,
        %Tai.Trading.Order{status: :expired} = updated_order
      }

      assert previous_order.client_id == order.client_id
      assert previous_order.executed_size == 0
      assert updated_order.client_id == order.client_id
      assert updated_order.executed_size == 0
    end

    test "expires unfilled sell orders", %{callback: callback} do
      order =
        Tai.Trading.OrderPipeline.sell_limit(
          :test_account_a,
          :btc_usd_expired,
          10_000.1,
          0.1,
          :fok,
          callback
        )

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{status: :enqueued} = previous_order,
        %Tai.Trading.Order{status: :expired} = updated_order
      }

      assert previous_order.client_id == order.client_id
      assert previous_order.executed_size == 0
      assert updated_order.client_id == order.client_id
      assert updated_order.executed_size == 0
    end

    test "updates the executed size of filled buy orders", %{callback: callback} do
      log_msg =
        capture_log(fn ->
          order =
            Tai.Trading.OrderPipeline.buy_limit(
              :test_account_a,
              :btc_usd_success,
              100.1,
              0.1,
              :fok,
              callback
            )

          assert_receive {
            :callback_fired,
            %Tai.Trading.Order{status: :enqueued} = previous_order,
            %Tai.Trading.Order{status: :filled} = updated_order
          }

          assert previous_order.client_id == order.client_id
          assert previous_order.executed_size == 0
          assert updated_order.client_id == order.client_id
          assert updated_order.executed_size == 0.1
        end)

      assert log_msg =~ "order filled - client_id:"
    end

    test "updates the executed size of filled sell orders", %{callback: callback} do
      order =
        Tai.Trading.OrderPipeline.sell_limit(
          :test_account_a,
          :btc_usd_success,
          10_000.1,
          0.1,
          :fok,
          callback
        )

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{status: :enqueued} = previous_order,
        %Tai.Trading.Order{status: :filled} = updated_order
      }

      assert previous_order.client_id == order.client_id
      assert previous_order.executed_size == 0
      assert updated_order.client_id == order.client_id
      assert updated_order.executed_size == 0.1
    end
  end

  describe "good til canceled" do
    test "pends unfilled buy orders", %{callback: callback} do
      log_msg =
        capture_log(fn ->
          order =
            Tai.Trading.OrderPipeline.buy_limit(
              :test_account_a,
              :btc_usd_pending,
              100.1,
              0.1,
              :gtc,
              callback
            )

          assert_receive {
            :callback_fired,
            %Tai.Trading.Order{status: :enqueued} = previous_order,
            %Tai.Trading.Order{status: :pending} = updated_order
          }

          assert previous_order.client_id == order.client_id
          assert previous_order.executed_size == 0
          assert updated_order.client_id == order.client_id
          assert updated_order.executed_size == 0
        end)

      assert log_msg =~ "order pending - client_id:"
    end

    test "pends unfilled sell orders", %{callback: callback} do
      log_msg =
        capture_log(fn ->
          order =
            Tai.Trading.OrderPipeline.sell_limit(
              :test_account_a,
              :btc_usd_pending,
              100_000.1,
              0.01,
              :gtc,
              callback
            )

          assert_receive {
            :callback_fired,
            %Tai.Trading.Order{status: :enqueued} = previous_order,
            %Tai.Trading.Order{status: :pending} = updated_order
          }

          assert previous_order.client_id == order.client_id
          assert previous_order.server_id == nil
          assert previous_order.executed_size == 0
          assert updated_order.client_id == order.client_id
          assert updated_order.server_id != nil
          assert updated_order.executed_size == 0
        end)

      assert log_msg =~ "order pending - client_id:"
    end
  end

  test "records the error and its reason", %{callback: callback} do
    log_msg =
      capture_log(fn ->
        order =
          Tai.Trading.OrderPipeline.buy_limit(
            :test_account_a,
            :btc_usd_unknown_error,
            100.1,
            0.1,
            :fok,
            callback
          )

        assert_receive {
          :callback_fired,
          %Tai.Trading.Order{status: :enqueued} = previous_order,
          %Tai.Trading.Order{status: :error} = updated_order
        }

        assert previous_order.client_id == order.client_id
        assert previous_order.error_reason == nil
        assert updated_order.client_id == order.client_id
        assert updated_order.error_reason == :unknown_error
        :timer.sleep(100)
      end)

    assert log_msg =~ "order error - client_id:"
    assert log_msg =~ ", ':unknown_error'"
  end

  test "logs a warning when the order is not buy or sell limit" do
    log_msg =
      capture_log(fn ->
        unhandled_order = %Tai.Trading.Order{
          side: 'magic_side',
          type: 'magic_type',
          client_id: :ignore,
          enqueued_at: :ignore,
          account_id: :ignore,
          price: :ignore,
          size: :ignore,
          status: :ignore,
          symbol: :ignore,
          time_in_force: :ignore
        }

        Tai.Trading.OrderPipeline.Send.call(unhandled_order)

        :timer.sleep(100)
      end)

    assert log_msg =~ "order error - client_id:"
    assert log_msg =~ ", cannot send unhandled order type 'magic_side magic_type'"
  end
end
