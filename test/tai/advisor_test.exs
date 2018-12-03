defmodule Tai.AdvisorTest do
  use ExUnit.Case, async: false
  doctest Tai.Advisor

  defmodule MyAdvisor do
    use Tai.Advisor

    def handle_order_updated(:raise_error, _, _) do
      raise "An Error!"

      :ok
    end

    def handle_order_updated(old_order, updated_order, state) do
      send(:test, {:fired_handle_order_updated, old_order, updated_order, state})
      counter = state.store |> Map.get(:counter, 0)
      new_store = state.store |> Map.put(:counter, counter + 1)

      {:ok, new_store}
    end
  end

  setup do
    Process.register(self(), :test)
    advisor_name = Tai.Advisor.to_name(:group_a, :my_advisor)

    start_supervised!({Tai.Events, 1})

    start_supervised!(
      {MyAdvisor,
       [
         group_id: :group_a,
         advisor_id: :my_advisor,
         products: [],
         config: %{}
       ]}
    )

    {:ok, %{advisor_name: advisor_name}}
  end

  describe ".order_updated" do
    test "executes the 'handle_order_updated' callback", %{advisor_name: advisor_name} do
      Tai.Advisor.order_updated(advisor_name, :old_order, :updated_order)

      assert_receive {:fired_handle_order_updated, :old_order, :updated_order, _}
    end

    test "can update the run store map", %{advisor_name: advisor_name} do
      Tai.Advisor.order_updated(advisor_name, :old_order, :updated_order)

      assert_receive {:fired_handle_order_updated, :old_order, :updated_order, original_state}
      assert original_state.store == %{}

      Tai.Advisor.order_updated(advisor_name, :old_order, :updated_order)

      assert_receive {:fired_handle_order_updated, :old_order, :updated_order, updated_state}
      assert updated_state.store == %{counter: 1}
    end

    test "broadcasts an event when an error is raised in the callback", %{
      advisor_name: advisor_name
    } do
      Tai.Events.firehose_subscribe()

      Tai.Advisor.order_updated(advisor_name, :raise_error, :updated_order)

      assert_receive {Tai.Event, %Tai.Events.AdvisorOrderUpdatedError{}}
    end
  end
end
