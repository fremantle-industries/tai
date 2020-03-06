defmodule Tai.Trading.Orders.CreateErrorTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Mock
  alias Tai.TestSupport.Mocks
  alias Tai.Trading.{Order, Orders, OrderSubmissions}

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

    test "#{side} records the error reason" do
      submission =
        Support.OrderSubmissions.build_with_callback(@submission_type, @submission_attrs)

      {:ok, _} = Orders.create(submission)

      assert_receive {
        :callback_fired,
        nil,
        %Order{status: :enqueued}
      }

      assert_receive {
        :callback_fired,
        %Order{status: :enqueued},
        %Order{status: :create_error} = error_order
      }

      assert error_order.error_reason == :mock_not_found
      assert %DateTime{} = error_order.last_received_at
    end

    test "#{side} rescues adapter errors" do
      submission =
        Support.OrderSubmissions.build_with_callback(@submission_type, @submission_attrs)

      Mocks.Responses.Orders.Error.create_raise(submission, "Venue Adapter Create Raised Error")
      {:ok, _} = Orders.create(submission)

      assert_receive {
        :callback_fired,
        nil,
        %Order{status: :enqueued}
      }

      assert_receive {
        :callback_fired,
        %Order{status: :enqueued},
        %Order{status: :create_error} = error_order
      }

      assert %DateTime{} = error_order.last_received_at
      assert {:unhandled, {error, [stack_1 | _]}} = error_order.error_reason
      assert error == %RuntimeError{message: "Venue Adapter Create Raised Error"}
      assert {Tai.VenueAdapters.Mock, _, _, [file: _, line: _]} = stack_1
    end
  end)
end
