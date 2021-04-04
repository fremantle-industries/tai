defmodule Tai.Orders.CreateFilledTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Mock
  import Support.Orders
  alias Tai.TestSupport.Mocks
  alias Tai.Orders.{Order, OrderSubmissions}

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
    {:buy, OrderSubmissions.BuyLimitFok},
    {:sell, OrderSubmissions.SellLimitFok}
  ]
  |> Enum.each(fn {side, submission_type} ->
    @submission_type submission_type

    test "#{side} updates the relevant attributes" do
      original_qty = Decimal.new(10)

      submission =
        Support.OrderSubmissions.build_with_callback(@submission_type, %{
          venue_id: @venue,
          credential_id: @credential,
          qty: original_qty
        })

      Mocks.Responses.Orders.FillOrKill.filled(@venue_order_id, submission)
      {:ok, _} = Tai.Orders.create(submission)

      assert_receive {
        :callback_fired,
        nil,
        %Order{status: :enqueued}
      }

      assert_receive {
        :callback_fired,
        %Order{status: :enqueued},
        %Order{status: :filled} = filled_order
      }

      assert filled_order.venue_order_id == @venue_order_id
      assert filled_order.leaves_qty == Decimal.new(0)
      assert filled_order.cumulative_qty == original_qty
      assert filled_order.qty == original_qty
      assert %DateTime{} = filled_order.last_received_at
      assert %DateTime{} = filled_order.last_venue_timestamp
    end
  end)
end
