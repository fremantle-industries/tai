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
    Tai.Trading.OrderPipeline.enqueue(%Tai.Trading.Orders.BuyLimit{
      venue_id: :test_exchange_a,
      account_id: :main,
      product_symbol: :btc_usd,
      price: 100.1,
      qty: 0.1,
      time_in_force: :fok,
      order_updated_callback: fire_order_callback(self())
    })

    assert_receive {
      :callback_fired,
      %Tai.Trading.Order{status: :enqueued},
      %Tai.Trading.Order{status: :error}
    }
  end

  test "broadcasts an event with the reason for the error" do
    order =
      Tai.Trading.OrderPipeline.enqueue(%Tai.Trading.Orders.BuyLimit{
        venue_id: :test_exchange_a,
        account_id: :main,
        product_symbol: :btc_usd,
        price: 100.1,
        qty: 0.1,
        time_in_force: :fok
      })

    client_id = order.client_id

    assert_receive {Tai.Event,
                    %Tai.Events.OrderUpdated{
                      client_id: ^client_id,
                      status: :error,
                      error_reason: :mock_not_found
                    }}
  end
end
