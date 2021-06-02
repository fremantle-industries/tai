defmodule Tai.Orders.CreateEnqueuedTest do
  use Tai.TestSupport.DataCase, async: false
  alias Tai.Orders.Submissions

  @venue_order_id "df8e6bd0-a40a-42fb-8fea-b33ef4e34f14"
  @venue :venue_a
  @credential :main
  @credentials Map.put(%{}, @credential, %{})
  @submission_attrs %{venue_id: @venue, credential_id: @credential}

  setup do
    mock_venue(id: @venue, credentials: @credentials, adapter: Tai.VenueAdapters.Mock)

    :ok
  end

  [
    {:buy, Submissions.BuyLimitGtc},
    {:sell, Submissions.SellLimitGtc}
  ]
  |> Enum.each(fn {side, submission_type} ->
    @side side
    @submission_type submission_type

    test "#{side} enqueues the order" do
      submission = Support.Orders.build_submission(@submission_type, @submission_attrs)
      Mocks.Responses.Orders.GoodTillCancel.open(@venue_order_id, submission)

      assert {:ok, order} = Tai.Orders.create(submission)
      assert order.client_id != nil
      assert order.venue_order_id == nil
      assert order.venue_id == submission.venue_id
      assert order.credential_id == submission.credential_id
      assert order.product_symbol == submission.product_symbol
      assert order.product_type == submission.product_type
      assert order.side == @side
      assert order.status == :enqueued
      assert order.price == submission.price
      assert order.qty == submission.qty
      assert order.time_in_force == :gtc
      assert order.last_received_at == nil
      assert order.last_venue_timestamp == nil
    end
  end)
end
