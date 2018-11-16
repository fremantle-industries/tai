defmodule Tai.Trading.OrderPipeline.ErrorsTest do
  use ExUnit.Case, async: false

  import Tai.TestSupport.Helpers

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    start_supervised!(Tai.TestSupport.Mocks.Server)
    {:ok, _} = Application.ensure_all_started(:tai)
    Tai.Events.firehose_subscribe()

    :ok
  end

  test "fires the callback" do
    Tai.Trading.OrderPipeline.buy_limit(
      :test_exchange_a,
      :main,
      :btc_usd,
      100.1,
      0.1,
      :fok,
      fire_order_callback(self())
    )

    assert_receive {
      :callback_fired,
      %Tai.Trading.Order{status: :enqueued},
      %Tai.Trading.Order{status: :error}
    }
  end

  test "broadcasts an event with the reason for the error" do
    order =
      Tai.Trading.OrderPipeline.buy_limit(
        :test_exchange_a,
        :main,
        :btc_usd,
        100.1,
        0.1,
        :fok
      )

    client_id = order.client_id

    assert_receive {Tai.Event,
                    %Tai.Events.OrderUpdated{
                      client_id: ^client_id,
                      status: :error,
                      error_reason: :mock_not_found
                    }}
  end
end
