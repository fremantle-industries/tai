defmodule Tai.Orders.CreateAcceptedTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Mock
  import Support.Orders
  alias Tai.TestSupport.Mocks
  alias Tai.Orders.{Order, Submissions}

  @venue_order_id "df8e6bd0-a40a-42fb-8fea-b33ef4e34f14"
  @venue :venue_a
  @credential :main
  @credentials Map.put(%{}, @credential, %{})
  @submission_attrs %{venue_id: @venue, credential_id: @credential}

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

    test "#{side} records the venue order id & timestamp" do
      submission = build_submission_with_callback(@submission_type, @submission_attrs)
      Mocks.Responses.Orders.GoodTillCancel.create_accepted(@venue_order_id, submission)

      {:ok, _} = Tai.Orders.create(submission)

      assert_receive {
        :callback_fired,
        nil,
        %Order{status: :enqueued}
      }

      assert_receive {
        :callback_fired,
        %Order{status: :enqueued},
        %Order{status: :create_accepted} = accepted_order
      }

      assert accepted_order.venue_order_id == @venue_order_id
      assert %DateTime{} = accepted_order.last_received_at
      assert %DateTime{} = accepted_order.last_venue_timestamp
    end
  end)
end
