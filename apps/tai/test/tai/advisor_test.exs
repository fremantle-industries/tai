defmodule Tai.AdvisorTest do
  use ExUnit.Case, async: false

  defmodule NoOpAdvisor do
    use Tai.Advisor
    def handle_inside_quote(_, _, _, _, state), do: {:ok, state.store}
  end

  defmodule CallbackAdvisor do
    use Tai.Advisor

    def handle_inside_quote(_, _, _, _, state), do: {:ok, state.store}

    def after_start(state) do
      send(Tai.AdvisorTest, {:after_start_callback, state})
      {:ok, state.store}
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

    start!(CallbackAdvisor, :init_trades, :my_advisor, [])

    assert_receive {:after_start_callback, state}
    assert %Tai.Advisor.State{} = state
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
