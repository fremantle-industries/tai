defmodule Tai.Orders.CreateOpenTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Mock
  import Support.Orders
  alias Tai.TestSupport.Mocks
  alias Tai.Orders.{Order, Submissions}

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
    {:buy, Submissions.BuyLimitGtc},
    {:sell, Submissions.SellLimitGtc}
  ]
  |> Enum.each(fn {side, submission_type} ->
    @submission_type submission_type

    test "#{side} updates the relevant attributes" do
      original_price = Decimal.new(2000)
      original_qty = Decimal.new(10)

      submission =
        Support.Orders.Submissions.build_with_callback(@submission_type, %{
          venue_id: @venue,
          credential_id: @credential,
          price: original_price,
          qty: original_qty
        })

      cumulative_qty = Decimal.new(4)

      Mocks.Responses.Orders.GoodTillCancel.open(@venue_order_id, submission, %{
        cumulative_qty: cumulative_qty
      })

      {:ok, _} = Tai.Orders.create(submission)

      assert_receive {
        :callback_fired,
        nil,
        %Order{status: :enqueued}
      }

      assert_receive {
        :callback_fired,
        %Order{status: :enqueued},
        %Order{status: :open} = open_order
      }

      assert open_order.venue_order_id == @venue_order_id
      assert open_order.leaves_qty == Decimal.new(6)
      assert open_order.cumulative_qty == Decimal.new(4)
      assert open_order.qty == Decimal.new(10)
      assert %DateTime{} = open_order.last_received_at
      assert %DateTime{} = open_order.last_venue_timestamp
    end
  end)
end
