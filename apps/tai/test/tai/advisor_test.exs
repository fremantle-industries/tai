defmodule Tai.AdvisorTest do
  use ExUnit.Case, async: false

  defmodule MyAdvisor do
    use Tai.Advisor
    def handle_inside_quote(_, _, _, _, state), do: {:ok, state.store}
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

  defp start!(group_id, advisor_id, opts) do
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
