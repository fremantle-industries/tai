defmodule Tai.Orders.CreateErrorTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Mock
  import Support.Orders
  alias Tai.TestSupport.Mocks
  alias Tai.Orders.{Order, Submissions}

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

    test "#{side} records the error reason" do
      submission = Support.Orders.Submissions.build_with_callback(@submission_type, @submission_attrs)

      {:ok, _} = Tai.Orders.create(submission)

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
      assert error_order.last_received_at != nil
    end

    test "#{side} rescues adapter errors" do
      submission = Support.Orders.Submissions.build_with_callback(@submission_type, @submission_attrs)

      Mocks.Responses.Orders.Error.create_raise(submission, "Venue Adapter Create Raised Error")
      {:ok, _} = Tai.Orders.create(submission)

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

      assert error_order.last_received_at != nil
      assert {:unhandled, {error, [stack_1 | _]}} = error_order.error_reason
      assert error == %RuntimeError{message: "Venue Adapter Create Raised Error"}
      assert {Tai.VenueAdapters.Mock, _, _, [file: _, line: _]} = stack_1
    end
  end)
end
