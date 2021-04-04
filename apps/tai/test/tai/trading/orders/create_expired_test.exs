defmodule Tai.Trading.Orders.CreateExpiredTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Mock
  import Support.Orders
  alias Tai.TestSupport.Mocks
  alias Tai.Trading.{Order, Orders, OrderSubmissions}

  @venue_order_id "df8e6bd0-a40a-42fb-8fea-b33ef4e34f14"
  @venue :venue_a
  @credential :main
  @credentials Map.put(%{}, @credential, %{})

  setup do
    setup_orders(&start_supervised!/1)
    mock_venue(id: @venue, credentials: @credentials, adapter: Tai.VenueAdapters.Mock)

    :ok
  end

  [
    {:buy, OrderSubmissions.BuyLimitIoc},
    {:sell, OrderSubmissions.SellLimitIoc}
  ]
  |> Enum.each(fn {side, submission_type} ->
    @submission_type submission_type

    test "#{side} updates the relevant attributes" do
      original_qty = Decimal.new(10)
      cumulative_qty = Decimal.new(3)

      submission =
        Support.OrderSubmissions.build_with_callback(@submission_type, %{
          venue_id: @venue,
          credential_id: @credential,
          qty: original_qty
        })

      Mocks.Responses.Orders.ImmediateOrCancel.expired(@venue_order_id, submission, %{
        cumulative_qty: cumulative_qty
      })

      {:ok, _} = Orders.create(submission)

      assert_receive {
        :callback_fired,
        nil,
        %Order{status: :enqueued}
      }

      assert_receive {
        :callback_fired,
        %Order{status: :enqueued},
        %Order{status: :expired} = expired_order
      }

      assert expired_order.venue_order_id == @venue_order_id
      assert expired_order.leaves_qty == Decimal.new(0)
      assert expired_order.cumulative_qty == cumulative_qty
      assert expired_order.qty == original_qty
      assert %DateTime{} = expired_order.last_venue_timestamp
    end
  end)
end
