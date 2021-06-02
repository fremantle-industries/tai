defmodule Tai.AdvisorTest do
  use Tai.TestSupport.DataCase, async: false

  defmodule NoOpAdvisor do
    use Tai.Advisor
    def handle_event(_, state), do: {:ok, state.store}
  end

  defmodule CallbackAdvisor do
    use Tai.Advisor

    def handle_event(_, state), do: {:ok, state.store}

    def after_start(state) do
      send(Tai.AdvisorTest, :after_start_callback)
      store = Map.put(state.store, :after_start_store, :is_updatable)
      {:ok, store}
    end

    def on_terminate(_terminate_reason, _state) do
      send(Tai.AdvisorTest, :on_terminate_callback)
    end
  end

  describe ".start_link" do
    test "can initialize run store" do
      advisor_pid = start!(NoOpAdvisor, :init_run_store, :my_advisor, store: %{initialized: true})
      state = :sys.get_state(advisor_pid)

      assert state.store.initialized == true

      Process.exit(advisor_pid, :kill)
    end

    test "can initialize trades" do
      advisor_pid = start!(NoOpAdvisor, :init_trades, :my_advisor, trades: [:a])
      state = :sys.get_state(advisor_pid)

      assert state.trades == [:a]

      Process.exit(advisor_pid, :kill)
    end
  end

  test "fires the after_start callback" do
    Process.register(self(), __MODULE__)

    advisor_pid = start!(CallbackAdvisor, :init_trades, :my_advisor, [])

    assert_receive :after_start_callback
    assert %Tai.Advisor.State{store: store} = :sys.get_state(advisor_pid)
    assert %{after_start_store: :is_updatable} = store

    Process.exit(advisor_pid, :kill)
  end

  describe "#on_terminate/2" do
    test "is called when advisor receives a :shutdown signal and is not linked" do
      Process.register(self(), __MODULE__)

      advisor_pid = start!(CallbackAdvisor, :init_trades, :my_advisor, [])
      assert_receive :after_start_callback

      ref = Process.monitor(advisor_pid)
      Process.unlink(advisor_pid)
      Process.exit(advisor_pid, :shutdown)

      assert_receive :on_terminate_callback
      assert_receive {:DOWN, ^ref, :process, ^advisor_pid, reason}
      assert reason == :shutdown
    end

    test "is called when advisor receives a :shutdown signal and is linked" do
      Process.register(self(), __MODULE__)
      Process.flag(:trap_exit, true)

      advisor_pid = start!(CallbackAdvisor, :init_trades, :my_advisor, [])
      assert_receive :after_start_callback

      Process.exit(advisor_pid, :shutdown)

      assert_receive :on_terminate_callback
      assert_receive {:EXIT, ^advisor_pid, reason}
      assert reason == :shutdown
    end
  end

  defp start!(advisor, group_id, advisor_id, opts) do
    products = Keyword.get(opts, :products, [])
    config = Keyword.get(opts, :config, %{})
    trades = Keyword.get(opts, :trades, [])
    run_store = Keyword.get(opts, :store, %{})

    {:ok, pid} = advisor.start_link(
      group_id: group_id,
      advisor_id: advisor_id,
      products: products,
      config: config,
      store: run_store,
      trades: trades
    )
    pid
  end
end
