defmodule Tai.Exchanges.BalanceTest do
  use ExUnit.Case
  doctest Tai.Exchanges.Balance

  defp all do
    Tai.Exchanges.Balance.all(:my_test_exchange, :my_test_account)
  end

  defp lock_range(asset, min, max) do
    range = Tai.Exchanges.BalanceRange.new(asset, min, max)
    Tai.Exchanges.Balance.lock_range(:my_test_exchange, :my_test_account, range)
  end

  defp unlock(asset, qty) do
    balance_change_request = Tai.Exchanges.BalanceChangeRequest.new(asset, qty)
    Tai.Exchanges.Balance.unlock(:my_test_exchange, :my_test_account, balance_change_request)
  end

  setup do
    balances = %{
      btc: Tai.Exchanges.BalanceDetail.new(1.1, 1.1),
      ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0.1)
    }

    start_supervised!({
      Tai.Exchanges.Balance,
      [exchange_id: :my_test_exchange, account_id: :my_test_account, balances: balances]
    })

    :ok
  end

  describe "#all" do
    test "returns a map of details for all assets in the account" do
      assert all() == %{
               btc: Tai.Exchanges.BalanceDetail.new(1.1, 1.1),
               ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0.1)
             }
    end
  end

  describe "#lock_range" do
    test "returns max when = free balance" do
      assert lock_range(:btc, 0, 1.1) == {:ok, Decimal.new(1.1)}

      assert all() == %{
               btc: Tai.Exchanges.BalanceDetail.new(0.0, 2.2),
               ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0.1)
             }
    end

    test "returns max when < free balance" do
      assert lock_range(:btc, 0, 1.0) == {:ok, Decimal.new(1.0)}

      assert all() == %{
               btc: Tai.Exchanges.BalanceDetail.new(0.1, 2.1),
               ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0.1)
             }
    end

    test "returns free balance when max >= free balance and min = free balance" do
      assert lock_range(:btc, 1.1, 1.2) == {:ok, Decimal.new(1.1)}

      assert all() == %{
               btc: Tai.Exchanges.BalanceDetail.new(0.0, 2.2),
               ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0.1)
             }
    end

    test "returns free balance when max >= free balance and min < free balance" do
      assert lock_range(:btc, 1.0, 1.2) == {:ok, Decimal.new(1.1)}

      assert all() == %{
               btc: Tai.Exchanges.BalanceDetail.new(0.0, 2.2),
               ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0.1)
             }
    end

    test "returns an error tuple when the asset doesn't exist" do
      assert lock_range(:xbt, 0.1, 1.2) == {:error, :not_found}

      assert all() == %{
               btc: Tai.Exchanges.BalanceDetail.new(1.1, 1.1),
               ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0.1)
             }
    end

    test "returns an error tuple when min > free balance" do
      assert lock_range(:btc, 1.11, 1.2) == {:error, :insufficient_balance}

      assert all() == %{
               btc: Tai.Exchanges.BalanceDetail.new(1.1, 1.1),
               ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0.1)
             }
    end

    test "returns an error tuple when min > max" do
      assert lock_range(:btc, 0.11, 0.1) == {:error, :min_greater_than_max}

      assert all() == %{
               btc: Tai.Exchanges.BalanceDetail.new(1.1, 1.1),
               ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0.1)
             }
    end

    test "returns an error tuple when min < 0" do
      assert lock_range(:btc, -0.1, 0.1) == {:error, :min_less_than_zero}

      assert all() == %{
               btc: Tai.Exchanges.BalanceDetail.new(1.1, 1.1),
               ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0.1)
             }
    end
  end

  describe "#unlock" do
    test "unlocks the balance for the asset" do
      assert unlock(:btc, 1.0) == :ok

      assert all() == %{
               btc: Tai.Exchanges.BalanceDetail.new(2.1, 0.1),
               ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0.1)
             }
    end

    test "doesn't unlock the balance if the asset doesn't exist" do
      assert unlock(:xbt, 1.0) == {:error, :not_found}

      assert all() == %{
               btc: Tai.Exchanges.BalanceDetail.new(1.1, 1.1),
               ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0.1)
             }
    end

    test "doesn't unlock the balance if there is insufficient funds" do
      assert unlock(:btc, 1.11) == {:error, :insufficient_balance}

      assert all() == %{
               btc: Tai.Exchanges.BalanceDetail.new(1.1, 1.1),
               ltc: Tai.Exchanges.BalanceDetail.new(0.1, 0.1)
             }
    end
  end
end
