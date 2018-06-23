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

  describe "#lock" do
    test "locks the balance for the asset" do
      balance_change_request = Tai.Exchanges.BalanceChangeRequest.new(:btc, 1.0)

      assert Tai.Exchanges.Balance.lock(:my_test_account, balance_change_request) == :ok

      assert Tai.Exchanges.Balance.all(:my_test_account) == %{
               btc: Tai.Exchanges.BalanceDetail.new(0.1, 2.1),
               ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0.1),
               eth: Tai.Exchanges.BalanceDetail.new(0.2, 0.2)
             }
    end

    test "doesn't lock the balance if the asset doesn't exist" do
      balance_change_request = Tai.Exchanges.BalanceChangeRequest.new(:xbt, 1.0)

      assert Tai.Exchanges.Balance.lock(:my_test_account, balance_change_request) ==
               {:error, :not_found}

      assert Tai.Exchanges.Balance.all(:my_test_account) == %{
               btc: Tai.Exchanges.BalanceDetail.new(1.1, 1.1),
               ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0.1),
               eth: Tai.Exchanges.BalanceDetail.new(0.2, 0.2)
             }
    end

    test "doesn't lock the balance if there is insufficient funds" do
      balance_change_request = Tai.Exchanges.BalanceChangeRequest.new(:btc, 1.11)

      assert Tai.Exchanges.Balance.lock(:my_test_account, balance_change_request) ==
               {:error, :insufficient_balance}

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
