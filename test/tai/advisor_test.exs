defmodule Tai.AdvisorTest do
  use ExUnit.Case, async: false
  doctest Tai.Advisor

  defmodule MyAdvisor do
    use Tai.Advisor
    def handle_inside_quote(_, _, _, _, state), do: {:ok, state.store}
  end

  describe ".start_link" do
    test "can initialize run store" do
      start_supervised!(
        {MyAdvisor,
         [
           group_id: :init_run_store,
           advisor_id: :my_advisor,
           products: [],
           config: %{},
           store: %{initialized: true}
         ]}
      )

      advisor_name = Tai.Advisor.to_name(:init_run_store, :my_advisor)
      state = :sys.get_state(advisor_name)

      assert state.store.initialized == true
    end

    test "can initialize trades" do
      start_supervised!(
        {MyAdvisor,
         [
           group_id: :init_trades,
           advisor_id: :my_advisor,
           products: [],
           config: %{},
           store: %{},
           trades: [:a]
         ]}
      )

      advisor_name = Tai.Advisor.to_name(:init_trades, :my_advisor)
      state = :sys.get_state(advisor_name)

      assert state.trades == [:a]
    end
  end

  describe ".cast_order_updated/4" do
    setup do
      Process.register(self(), :test)
      advisor_name = start!(:group_a, :my_advisor)
      {:ok, %{advisor_name: advisor_name}}
    end

    test "executes the given callback function", %{advisor_name: advisor_name} do
      callback = fn old_order, updated_order, state ->
        send(:test, {:fired_order_updated_callback, old_order, updated_order, state})
        :ok
      end

      Tai.Advisor.cast_order_updated(advisor_name, :old_order, :updated_order, callback)

      assert_receive {:fired_order_updated_callback, :old_order, :updated_order,
                      %Tai.Advisor.State{}}
    end

    test "can update the run store map with the return value of the callback", %{
      advisor_name: advisor_name
    } do
      callback = fn old_order, updated_order, state ->
        send(:test, {:fired_order_updated_callback, old_order, updated_order, state})
        counter = state.store |> Map.get(:counter, 0)
        new_store = state.store |> Map.put(:counter, counter + 1)

        {:ok, new_store}
      end

      Tai.Advisor.cast_order_updated(advisor_name, :old_order, :updated_order, callback)

      assert_receive {:fired_order_updated_callback, :old_order, :updated_order, original_state}
      assert original_state.store == %{}

      Tai.Advisor.cast_order_updated(advisor_name, :old_order, :updated_order, callback)

      assert_receive {:fired_order_updated_callback, :old_order, :updated_order, updated_state}
      assert updated_state.store == %{counter: 1}
    end

    test "broadcasts an event when an error is raised in the callback", %{
      advisor_name: advisor_name
    } do
      Tai.Events.firehose_subscribe()
      callback = fn _, _, _ -> raise "Callback Error!!!" end

      Tai.Advisor.cast_order_updated(advisor_name, :raise_error, :updated_order, callback)

      assert_receive {Tai.Event, %Tai.Events.AdvisorOrderUpdatedError{} = event, _}
      assert event.error == %RuntimeError{message: "Callback Error!!!"}
    end
  end

  describe ".cast_order_updated/5" do
    setup do
      Process.register(self(), :test)
      advisor_name = start!(:group_a, :my_advisor)
      {:ok, %{advisor_name: advisor_name}}
    end

    test "executes the given callback function", %{advisor_name: advisor_name} do
      callback = fn old_order, updated_order, opts, state ->
        send(:test, {:fired_order_updated_callback, old_order, updated_order, opts, state})
        :ok
      end

      Tai.Advisor.cast_order_updated(advisor_name, :old_order, :updated_order, callback, :opts)

      assert_receive {:fired_order_updated_callback, :old_order, :updated_order, :opts,
                      %Tai.Advisor.State{}}
    end

    test "can update the run store map with the return value of the callback", %{
      advisor_name: advisor_name
    } do
      callback = fn old_order, updated_order, opts, state ->
        send(:test, {:fired_order_updated_callback, old_order, updated_order, opts, state})
        counter = state.store |> Map.get(:counter, 0)
        new_store = state.store |> Map.put(:counter, counter + 1)

        {:ok, new_store}
      end

      Tai.Advisor.cast_order_updated(advisor_name, :old_order, :updated_order, callback, :opts)

      assert_receive {:fired_order_updated_callback, :old_order, :updated_order, :opts,
                      original_state}

      assert original_state.store == %{}

      Tai.Advisor.cast_order_updated(advisor_name, :old_order, :updated_order, callback, :opts)

      assert_receive {:fired_order_updated_callback, :old_order, :updated_order, :opts,
                      updated_state}

      assert updated_state.store == %{counter: 1}
    end

    test "broadcasts an event when an error is raised in the callback", %{
      advisor_name: advisor_name
    } do
      Tai.Events.firehose_subscribe()
      callback = fn _, _, _, _ -> raise "Callback Error!!!" end

      Tai.Advisor.cast_order_updated(advisor_name, :raise_error, :updated_order, callback, :opts)

      assert_receive {Tai.Event, %Tai.Events.AdvisorOrderUpdatedError{} = event, _}
      assert event.error == %RuntimeError{message: "Callback Error!!!"}
    end
  end

  defp start!(group_id, advisor_id) do
    start_supervised!({Tai.Events, 1})

    start_supervised!(
      {MyAdvisor,
       [
         group_id: group_id,
         advisor_id: advisor_id,
         products: [],
         config: %{}
       ]}
    )

    Tai.Advisor.to_name(group_id, advisor_id)
  end
end
