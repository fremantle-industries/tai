defmodule Tai.AdvisorTest do
  use ExUnit.Case, async: false

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
  end

  describe ".start_link" do
    test "can initialize run store" do
      pid = start!(NoOpAdvisor, :init_run_store, :my_advisor, store: %{initialized: true})
      state = :sys.get_state(pid)

      assert state.store.initialized == true
    end

    test "can initialize trades" do
      pid = start!(NoOpAdvisor, :init_trades, :my_advisor, trades: [:a])
      state = :sys.get_state(pid)

      assert state.trades == [:a]
    end
  end

  test "fires the after_start callback" do
    Process.register(self(), __MODULE__)

    advisor_pid = start!(CallbackAdvisor, :init_trades, :my_advisor, [])

    assert_receive :after_start_callback
    assert %Tai.Advisor.State{store: store} = :sys.get_state(advisor_pid)
    assert %{after_start_store: :is_updatable} = store
  end

  defp start!(advisor, group_id, advisor_id, opts) do
    products = Keyword.get(opts, :products, [])
    config = Keyword.get(opts, :config, %{})
    trades = Keyword.get(opts, :trades, [])
    run_store = Keyword.get(opts, :store, %{})

    start_supervised!({Tai.Events, 1})

    start_supervised!(
      {advisor,
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
