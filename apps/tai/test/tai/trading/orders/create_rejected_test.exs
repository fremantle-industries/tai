defmodule Tai.Trading.Orders.CreateRejectedTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Mock
  alias Tai.TestSupport.Mocks
  alias Tai.Trading.{Order, Orders, OrderSubmissions}

  @venue_order_id "df8e6bd0-a40a-42fb-8fea-b33ef4e34f14"
  @venue :venue_a
  @credential :main
  @credentials Map.put(%{}, @credential, %{})
  @submission_attrs %{venue_id: @venue, credential_id: @credential}

  setup do
    start_supervised!(Mocks.Server)
    start_supervised!({TaiEvents, 1})
    start_supervised!({Tai.Settings, Tai.Config.parse()})
    start_supervised!(Tai.Trading.OrderStore)
    start_supervised!(Tai.Venues.VenueStore)

    mock_venue(id: @venue, credentials: @credentials, adapter: Tai.VenueAdapters.Mock)

    :ok
  end

  [
    {:buy, OrderSubmissions.BuyLimitGtc},
    {:sell, OrderSubmissions.SellLimitGtc}
  ]
  |> Enum.each(fn {side, submission_type} ->
    @submission_type submission_type

    test "#{side} updates the relevant attributes" do
      submission =
        Support.OrderSubmissions.build_with_callback(@submission_type, @submission_attrs)

      Mocks.Responses.Orders.GoodTillCancel.rejected(@venue_order_id, submission)
      {:ok, _} = Orders.create(submission)

      assert_receive {
        :callback_fired,
        nil,
        %Order{status: :enqueued}
      }

      assert_receive {
        :callback_fired,
        %Order{status: :enqueued},
        %Order{status: :rejected} = rejected_order
      }

      assert rejected_order.venue_order_id == @venue_order_id
      assert %DateTime{} = rejected_order.last_venue_timestamp
    end
  end)
end
