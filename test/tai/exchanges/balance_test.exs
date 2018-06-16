defmodule Tai.Exchanges.BalanceTest do
  use ExUnit.Case, async: true
  doctest Tai.Exchanges.Balance

  test "all returns the details for all assets in the account" do
    balances = %{
      btc: Tai.Exchanges.BalanceDetail.new(1.1, 0),
      ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0),
      eth: Tai.Exchanges.BalanceDetail.new(0.2, 0)
    }

    start_supervised!({
      Tai.Exchanges.Balance,
      [account_id: :my_test_account, balances: balances]
    })

    assert Tai.Exchanges.Balance.all(:my_test_account) == balances
  end
end
