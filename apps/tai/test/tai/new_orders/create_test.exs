defmodule Tai.NewOrders.CreateTest do
  use Tai.TestSupport.DataCase, async: false
  alias Tai.NewOrders

  @venue_order_id "df8e6bd0-a40a-42fb-8fea-b33ef4e34f14"
  @venue :venue_a
  @credential :main
  @credentials Map.put(%{}, @credential, %{})
  @submission_attrs %{
    venue: @venue |> Atom.to_string(),
    credential: @credential |> Atom.to_string()
  }

  setup do
    mock_venue(id: @venue, credentials: @credentials, adapter: Tai.VenueAdapters.Mock)

    :ok
  end

  [
    {:buy, NewOrders.Submissions.BuyLimitGtc},
    {:sell, NewOrders.Submissions.SellLimitGtc}
  ]
  |> Enum.each(fn {side, submission_type} ->
    @submission_type submission_type

    test "#{side} enqueues the order and sends it to the venue" do
      submission = build_submission_with_callback(@submission_type, @submission_attrs)
      Mocks.Responses.NewOrders.GoodTillCancel.create_accepted(@venue_order_id, submission)

      {:ok, _} = Tai.NewOrders.create(submission)

      assert_receive {
        :callback_fired,
        nil,
        %NewOrders.Order{status: :enqueued},
        nil
      }

      assert_receive {
        :callback_fired,
        %NewOrders.Order{status: :enqueued},
        %NewOrders.Order{} = accepted_order,
        transition
      }

      assert %NewOrders.Transitions.AcceptCreate{} = transition
      assert accepted_order.status == :create_accepted
      assert accepted_order.venue_order_id == @venue_order_id
      assert %DateTime{} = accepted_order.last_received_at
      assert %DateTime{} = accepted_order.last_venue_timestamp

      saved_order = NewOrders.OrderRepo.get!(NewOrders.Order, accepted_order.client_id)
      assert saved_order.status == :create_accepted
    end

    test "#{side} records the error when it can't be created on the venue" do
      submission = build_submission_with_callback(@submission_type, @submission_attrs)

      assert {:ok, %NewOrders.Order{status: :enqueued}} = Tai.NewOrders.create(submission)

      assert_receive {
        :callback_fired,
        nil,
        %NewOrders.Order{status: :enqueued},
        nil
      }

      assert_receive {
        :callback_fired,
        %NewOrders.Order{status: :enqueued},
        %NewOrders.Order{} = updated_order,
        transition
      }

      assert %NewOrders.Transitions.VenueCreateError{} = transition
      assert transition.reason == :mock_not_found

      assert updated_order.status == :create_error
    end

    test "#{side} records a failed transition and doesn't execute the callback when the adapter returns an invalid response" do
      invalid_venue_order_id = 1234
      submission = build_submission_with_callback(@submission_type, @submission_attrs)
      Mocks.Responses.NewOrders.GoodTillCancel.create_accepted(invalid_venue_order_id, submission)

      {:ok, _} = Tai.NewOrders.create(submission)

      assert_receive {
        :callback_fired,
        nil,
        %NewOrders.Order{status: :enqueued},
        nil
      }

      refute_receive {
        :callback_fired,
        %NewOrders.Order{status: :enqueued},
        %NewOrders.Order{},
        _transition
      }

      failed_order_transitions = NewOrders.OrderRepo.all(NewOrders.FailedOrderTransition)
      assert length(failed_order_transitions) == 1
      failed_order_transition = Enum.at(failed_order_transitions, 0)
      assert failed_order_transition.type == "accept_create"
    end

    test "#{side} records an error when raised by the adapter" do
      submission = build_submission_with_callback(@submission_type, @submission_attrs)

      Mocks.Responses.NewOrders.Error.create_raise(
        submission,
        "Venue Adapter Create Raised Error"
      )

      {:ok, _} = Tai.NewOrders.create(submission)

      assert_receive {
        :callback_fired,
        nil,
        %NewOrders.Order{status: :enqueued},
        nil
      }

      assert_receive {
        :callback_fired,
        %NewOrders.Order{status: :enqueued},
        %NewOrders.Order{} = updated_order,
        transition
      }

      assert %NewOrders.Transitions.RescueCreateError{} = transition
      assert transition.error == %RuntimeError{message: "Venue Adapter Create Raised Error"}
      assert [stack_1 | _] = transition.stacktrace
      assert {Tai.VenueAdapters.Mock, _, _, [file: _, line: _]} = stack_1

      assert updated_order.status == :create_error
    end

    describe "#{side} skips" do
      setup do
        on_exit(fn ->
          Tai.Settings.enable_send_orders!()
        end)

        Tai.Settings.disable_send_orders!()
        :ok
      end

      test "when send orders is disabled" do
        submission = build_submission_with_callback(@submission_type, @submission_attrs)
        {:ok, _} = Tai.NewOrders.create(submission)

        assert_receive {
          :callback_fired,
          nil,
          %NewOrders.Order{status: :enqueued},
          nil
        }

        assert_receive {
          :callback_fired,
          %NewOrders.Order{status: :enqueued},
          %NewOrders.Order{} = skipped_order,
          transition
        }

        assert %NewOrders.Transitions.Skip{} = transition

        assert skipped_order.status == :skipped
        assert skipped_order.leaves_qty == Decimal.new(0)
      end
    end
  end)
end
