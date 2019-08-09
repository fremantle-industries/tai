defmodule Tai.AdvisorTest do
  use ExUnit.Case, async: false
  doctest Tai.Advisor

  defmodule MyAdvisor do
    use Tai.Advisor
    def handle_inside_quote(_, _, _, state), do: {:ok, state.store}

    def init(%Tai.Advisor.State{config: %{callback: callback}} = state) do
      callback.()
      super(state)
    end

    def init(state), do: super(state)
  end

  describe ".start_link" do
    test "can initialize run store" do
      pid = start!(:init_run_store, :my_advisor, store: %{initialized: true})
      state = :sys.get_state(pid)

      assert state.store.initialized == true
    end

    test "can initialize trades" do
      pid = start!(:init_trades, :my_advisor, trades: [:a])
      state = :sys.get_state(pid)

      assert state.trades == [:a]
    end
  end

  describe ".init/1" do
    test "can be overridden" do
      Process.register(self(), :test)
      callback = fn -> send(:test, :init_called) end
      start!(:init_override, :my_advisor, config: %{callback: callback})
      assert_receive :init_called
    end
  end

  describe ".cast_order_updated/4" do
    setup do
      Process.register(self(), :test)
      pid = start!(:group_a, :my_advisor)
      %{pid: pid}
    end

    test "executes the given callback function", %{pid: pid} do
      callback = fn old_order, updated_order, state ->
        send(:test, {:fired_order_updated_callback, old_order, updated_order, state})
        :ok
      end

      Tai.Advisor.cast_order_updated(pid, :old_order, :updated_order, callback)

      assert_receive {:fired_order_updated_callback, :old_order, :updated_order,
                      %Tai.Advisor.State{}}
    end

    test "can update the run store map with the return value of the callback", %{pid: pid} do
      callback = fn old_order, updated_order, state ->
        send(:test, {:fired_order_updated_callback, old_order, updated_order, state})
        counter = state.store |> Map.get(:counter, 0)
        new_store = state.store |> Map.put(:counter, counter + 1)

        {:ok, new_store}
      end

      Tai.Advisor.cast_order_updated(pid, :old_order, :updated_order, callback)

      assert_receive {:fired_order_updated_callback, :old_order, :updated_order, original_state}
      assert original_state.store == %{}

      Tai.Advisor.cast_order_updated(pid, :old_order, :updated_order, callback)

      assert_receive {:fired_order_updated_callback, :old_order, :updated_order, updated_state}
      assert updated_state.store == %{counter: 1}
    end

    test "broadcasts an event when an error is raised in the callback", %{pid: pid} do
      Tai.Events.firehose_subscribe()
      callback = fn _, _, _ -> raise "Callback Error!!!" end

      Tai.Advisor.cast_order_updated(pid, :raise_error, :updated_order, callback)

      assert_receive {Tai.Event, %Tai.Events.AdvisorOrderUpdatedError{} = event, _}
      assert event.error == %RuntimeError{message: "Callback Error!!!"}
    end
  end

  describe ".cast_order_updated/5" do
    setup do
      Process.register(self(), :test)
      pid = start!(:group_a, :my_advisor)
      %{pid: pid}
    end

    test "executes the given callback function", %{pid: pid} do
      callback = fn old_order, updated_order, opts, state ->
        send(:test, {:fired_order_updated_callback, old_order, updated_order, opts, state})
        :ok
      end

      Tai.Advisor.cast_order_updated(pid, :old_order, :updated_order, callback, :opts)

      assert_receive {:fired_order_updated_callback, :old_order, :updated_order, :opts,
                      %Tai.Advisor.State{}}
    end

    test "can update the run store map with the return value of the callback", %{pid: pid} do
      callback = fn old_order, updated_order, opts, state ->
        send(:test, {:fired_order_updated_callback, old_order, updated_order, opts, state})
        counter = state.store |> Map.get(:counter, 0)
        new_store = state.store |> Map.put(:counter, counter + 1)

        {:ok, new_store}
      end

      Tai.Advisor.cast_order_updated(pid, :old_order, :updated_order, callback, :opts)

      assert_receive {:fired_order_updated_callback, :old_order, :updated_order, :opts,
                      original_state}

      assert original_state.store == %{}

      Tai.Advisor.cast_order_updated(pid, :old_order, :updated_order, callback, :opts)

      assert_receive {:fired_order_updated_callback, :old_order, :updated_order, :opts,
                      updated_state}

      assert updated_state.store == %{counter: 1}
    end

    test "broadcasts an event when an error is raised in the callback", %{pid: pid} do
      Tai.Events.firehose_subscribe()
      callback = fn _, _, _, _ -> raise "Callback Error!!!" end

      Tai.Advisor.cast_order_updated(pid, :raise_error, :updated_order, callback, :opts)

      assert_receive {Tai.Event, %Tai.Events.AdvisorOrderUpdatedError{} = event, _}
      assert event.error == %RuntimeError{message: "Callback Error!!!"}
    end
  end

  defp start!(group_id, advisor_id, opts \\ []) do
    products = Keyword.get(opts, :products, [])
    config = Keyword.get(opts, :config, %{})
    trades = Keyword.get(opts, :trades, [])
    run_store = Keyword.get(opts, :store, %{})

    start_supervised!({Tai.Events, 1})

    start_supervised!(
      {MyAdvisor,
       [
         group_id: group_id,
         advisor_id: advisor_id,
         products: products,
         config: config,
         store: run_store,
         trades: trades
       ]}
    )
  end
end
