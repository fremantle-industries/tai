defmodule Tai.Orders.CancelTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Mock
  import Support.Orders
  alias Tai.Orders.{Order, Submissions}
  alias Tai.TestSupport.Mocks

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

    test "#{side} cancels the order on the venue" do
      submission = build_submission_with_callback(@submission_type, @submission_attrs)
      Mocks.Responses.Orders.GoodTillCancel.open(@venue_order_id, submission)

      {:ok, order} = Tai.Orders.create(submission)
      assert_receive {:callback_fired, %Order{status: :enqueued}, %Order{status: :open}}

      Mocks.Responses.Orders.GoodTillCancel.canceled(@venue_order_id)
      assert {:ok, %Order{status: :pending_cancel}} = Tai.Orders.cancel(order)
      assert_receive {:callback_fired, %Order{status: :open}, %Order{status: :pending_cancel}}
      assert_receive {:callback_fired, %Order{status: :pending_cancel}, %Order{status: :canceled}}
    end
  end)
end
