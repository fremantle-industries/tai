defmodule Tai.Exchanges.BalanceTest do
  use ExUnit.Case, async: true
  doctest Tai.Exchanges.Balance

  alias Tai.Exchanges.Balance

  test "all returns the values for all symbols in the account" do
    balances = %{
      btc: 1.1,
      ltc: 0.1,
      eth: 0.2
    }

    start_supervised!({Balance, [account_id: :my_test_account, balances: balances]})

    assert Balance.all(:my_test_account) == balances
  end
end
