defmodule Tai.Exchanges.BalanceTest do
  use ExUnit.Case
  doctest Tai.Exchanges.Balance

  setup do
    balances = %{
      btc: Tai.Exchanges.BalanceDetail.new(1.1, 1.1),
      ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0.1),
      eth: Tai.Exchanges.BalanceDetail.new(0.2, 0.2)
    }

    start_supervised!({
      Tai.Exchanges.Balance,
      [account_id: :my_test_account, balances: balances]
    })

    :ok
  end

  test "all returns the details for all assets in the account" do
    assert Tai.Exchanges.Balance.all(:my_test_account) == %{
             btc: Tai.Exchanges.BalanceDetail.new(1.1, 1.1),
             ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0.1),
             eth: Tai.Exchanges.BalanceDetail.new(0.2, 0.2)
           }
  end

  describe "#lock_all" do
    test "reserves balances for all of the requests" do
      balance_change_requests = [
        Tai.Exchanges.BalanceChangeRequest.new(:btc, 1.0),
        Tai.Exchanges.BalanceChangeRequest.new(:ltc, 0.1)
      ]

      assert Tai.Exchanges.Balance.lock_all(:my_test_account, balance_change_requests) == :ok

      assert Tai.Exchanges.Balance.all(:my_test_account) == %{
               btc: Tai.Exchanges.BalanceDetail.new(0.1, 2.1),
               ltc: Tai.Exchanges.BalanceDetail.new(0.0, 0.2),
               eth: Tai.Exchanges.BalanceDetail.new(0.2, 0.2)
             }
    end

    test "doesn't reserve any balances if there are insufficient funds for any of the requests" do
      balance_change_requests = [
        Tai.Exchanges.BalanceChangeRequest.new(:btc, 1.0),
        Tai.Exchanges.BalanceChangeRequest.new(:ltc, 0.11),
        Tai.Exchanges.BalanceChangeRequest.new(:ltc, 0.01)
      ]

      assert Tai.Exchanges.Balance.lock_all(:my_test_account, balance_change_requests) == {
               :error,
               [
                 {:insufficient_balance, Tai.Exchanges.BalanceChangeRequest.new(:ltc, 0.11)},
                 {:insufficient_balance, Tai.Exchanges.BalanceChangeRequest.new(:ltc, 0.01)}
               ]
             }

      assert Tai.Exchanges.Balance.all(:my_test_account) == %{
               btc: Tai.Exchanges.BalanceDetail.new(1.1, 1.1),
               ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0.1),
               eth: Tai.Exchanges.BalanceDetail.new(0.2, 0.2)
             }
    end

    test "doesn't reserve any balances if one of the assets doesn't exist" do
      balance_change_requests = [
        Tai.Exchanges.BalanceChangeRequest.new(:btc, 1.0),
        Tai.Exchanges.BalanceChangeRequest.new(:xbt, 1.0),
        Tai.Exchanges.BalanceChangeRequest.new(:ltc, 0.1)
      ]

      assert Tai.Exchanges.Balance.lock_all(:my_test_account, balance_change_requests) == {
               :error,
               [{:not_found, Tai.Exchanges.BalanceChangeRequest.new(:xbt, 1.0)}]
             }

      assert Tai.Exchanges.Balance.all(:my_test_account) == %{
               btc: Tai.Exchanges.BalanceDetail.new(1.1, 1.1),
               ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0.1),
               eth: Tai.Exchanges.BalanceDetail.new(0.2, 0.2)
             }
    end
  end

  describe "#unlock" do
    test "unlocks the balance for the asset" do
      balance_change_request = Tai.Exchanges.BalanceChangeRequest.new(:btc, 1.0)

      assert Tai.Exchanges.Balance.unlock(:my_test_account, balance_change_request) == :ok

      assert Tai.Exchanges.Balance.all(:my_test_account) == %{
               btc: Tai.Exchanges.BalanceDetail.new(2.1, 0.1),
               ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0.1),
               eth: Tai.Exchanges.BalanceDetail.new(0.2, 0.2)
             }
    end

    test "doesn't unlock the balance is the asset doesn't exist" do
      balance_change_request = Tai.Exchanges.BalanceChangeRequest.new(:xbt, 1.0)

      assert Tai.Exchanges.Balance.unlock(:my_test_account, balance_change_request) ==
               {:error, :not_found}

      assert Tai.Exchanges.Balance.all(:my_test_account) == %{
               btc: Tai.Exchanges.BalanceDetail.new(1.1, 1.1),
               ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0.1),
               eth: Tai.Exchanges.BalanceDetail.new(0.2, 0.2)
             }
    end

    test "doesn't unlock the balance is there is insufficient funds" do
      balance_change_request = Tai.Exchanges.BalanceChangeRequest.new(:btc, 1.11)

      assert Tai.Exchanges.Balance.unlock(:my_test_account, balance_change_request) ==
               {:error, :insufficient_balance}

      assert Tai.Exchanges.Balance.all(:my_test_account) == %{
               btc: Tai.Exchanges.BalanceDetail.new(1.1, 1.1),
               ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0.1),
               eth: Tai.Exchanges.BalanceDetail.new(0.2, 0.2)
             }
    end
  end
end
