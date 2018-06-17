defmodule Tai.Exchanges.BalanceTest do
  use ExUnit.Case, async: true
  doctest Tai.Exchanges.Balance

  setup do
    balances = %{
      btc: Tai.Exchanges.BalanceDetail.new(1.1, 0),
      ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0),
      eth: Tai.Exchanges.BalanceDetail.new(0.2, 0)
    }

    start_supervised!({
      Tai.Exchanges.Balance,
      [account_id: :my_test_account, balances: balances]
    })

    :ok
  end

  test "all returns the details for all assets in the account" do
    assert Tai.Exchanges.Balance.all(:my_test_account) == %{
             btc: Tai.Exchanges.BalanceDetail.new(1.1, 0),
             ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0),
             eth: Tai.Exchanges.BalanceDetail.new(0.2, 0)
           }
  end

  describe "#lock_all" do
    test "reserves balances for all of the requests" do
      lock_requests = [
        Tai.Exchanges.LockRequest.new(:btc, 1.0),
        Tai.Exchanges.LockRequest.new(:ltc, 0.1)
      ]

      assert Tai.Exchanges.Balance.lock_all(:my_test_account, lock_requests) == :ok

      assert Tai.Exchanges.Balance.all(:my_test_account) == %{
               btc: Tai.Exchanges.BalanceDetail.new(0.1, 1.0),
               ltc: Tai.Exchanges.BalanceDetail.new(0.0, 0.1),
               eth: Tai.Exchanges.BalanceDetail.new(0.2, 0)
             }
    end

    test "doesn't reserve any balances if one of the requests fails" do
      lock_requests = [
        Tai.Exchanges.LockRequest.new(:btc, 1.0),
        Tai.Exchanges.LockRequest.new(:ltc, 0.11),
        Tai.Exchanges.LockRequest.new(:ltc, 0.01)
      ]

      assert Tai.Exchanges.Balance.lock_all(:my_test_account, lock_requests) == {
               :error,
               [
                 Tai.Exchanges.LockRequest.new(:ltc, 0.11),
                 Tai.Exchanges.LockRequest.new(:ltc, 0.01)
               ]
             }

      assert Tai.Exchanges.Balance.all(:my_test_account) == %{
               btc: Tai.Exchanges.BalanceDetail.new(1.1, 0),
               ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0),
               eth: Tai.Exchanges.BalanceDetail.new(0.2, 0)
             }
    end

    test "doesn't reserve any balances if one of the assets doesn't exist" do
      lock_requests = [
        Tai.Exchanges.LockRequest.new(:btc, 1.0),
        Tai.Exchanges.LockRequest.new(:xbt, 1.0),
        Tai.Exchanges.LockRequest.new(:ltc, 0.1)
      ]

      assert Tai.Exchanges.Balance.lock_all(:my_test_account, lock_requests) == {
               :error,
               [Tai.Exchanges.LockRequest.new(:xbt, 1.0)]
             }

      assert Tai.Exchanges.Balance.all(:my_test_account) == %{
               btc: Tai.Exchanges.BalanceDetail.new(1.1, 0),
               ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0),
               eth: Tai.Exchanges.BalanceDetail.new(0.2, 0)
             }
    end
  end
end
