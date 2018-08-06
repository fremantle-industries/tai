defmodule Tai.Exchanges.AssetBalancesTest do
  use ExUnit.Case
  doctest Tai.Exchanges.AssetBalances

  import ExUnit.CaptureLog

  test "logs the free & locked balances on init" do
    log_msg =
      capture_log(fn ->
        start_asset_balances(:ok)
        :timer.sleep(100)
      end)

    assert log_msg =~ ~r/\[init,btc,1.1,1.1\]/
    assert log_msg =~ ~r/\[init,ltc,0.1,0.1\]/
  end

  describe "#all" do
    setup [:start_asset_balances]

    test "returns a map of balances for all assets in the account" do
      assert all() == %{
               btc: Tai.Exchanges.AssetBalance.new(1.1, 1.1),
               ltc: Tai.Exchanges.AssetBalance.new(0.1, 0.1)
             }
    end
  end

  describe "#lock_range" do
    setup [:start_asset_balances]

    test "returns max when = free balance" do
      assert lock_range(:btc, 0, 1.1) == {:ok, Decimal.new(1.1)}

      assert all() == %{
               btc: Tai.Exchanges.AssetBalance.new(0.0, 2.2),
               ltc: Tai.Exchanges.AssetBalance.new(0.1, 0.1)
             }
    end

    test "returns max when < free balance" do
      assert lock_range(:btc, 0, 1.0) == {:ok, Decimal.new(1.0)}

      assert all() == %{
               btc: Tai.Exchanges.AssetBalance.new(0.1, 2.1),
               ltc: Tai.Exchanges.AssetBalance.new(0.1, 0.1)
             }
    end

    test "returns free balance when max >= free balance and min = free balance" do
      assert lock_range(:btc, 1.1, 1.2) == {:ok, Decimal.new(1.1)}

      assert all() == %{
               btc: Tai.Exchanges.AssetBalance.new(0.0, 2.2),
               ltc: Tai.Exchanges.AssetBalance.new(0.1, 0.1)
             }
    end

    test "returns free balance when max >= free balance and min < free balance" do
      assert lock_range(:btc, 1.0, 1.2) == {:ok, Decimal.new(1.1)}

      assert all() == %{
               btc: Tai.Exchanges.AssetBalance.new(0.0, 2.2),
               ltc: Tai.Exchanges.AssetBalance.new(0.1, 0.1)
             }
    end

    test "returns an error tuple when the asset doesn't exist" do
      assert lock_range(:xbt, 0.1, 1.2) == {:error, :not_found}

      assert all() == %{
               btc: Tai.Exchanges.AssetBalance.new(1.1, 1.1),
               ltc: Tai.Exchanges.AssetBalance.new(0.1, 0.1)
             }
    end

    test "returns an error tuple when min > free balance" do
      assert lock_range(:btc, 1.11, 1.2) == {:error, :insufficient_balance}

      assert all() == %{
               btc: Tai.Exchanges.AssetBalance.new(1.1, 1.1),
               ltc: Tai.Exchanges.AssetBalance.new(0.1, 0.1)
             }
    end

    test "returns an error tuple when min > max" do
      assert lock_range(:btc, 0.11, 0.1) == {:error, :min_greater_than_max}

      assert all() == %{
               btc: Tai.Exchanges.AssetBalance.new(1.1, 1.1),
               ltc: Tai.Exchanges.AssetBalance.new(0.1, 0.1)
             }
    end

    test "returns an error tuple when min < 0" do
      assert lock_range(:btc, -0.1, 0.1) == {:error, :min_less_than_zero}

      assert all() == %{
               btc: Tai.Exchanges.AssetBalance.new(1.1, 1.1),
               ltc: Tai.Exchanges.AssetBalance.new(0.1, 0.1)
             }
    end

    test "logs the asset, locked quantity & range when successful" do
      log_msg =
        capture_log(fn ->
          lock_range(:btc, 0.5, 0.6)
          :timer.sleep(100)
        end)

      assert log_msg =~ ~r/\[lock_range_ok:btc,0.6,0.5..0.6\]/
    end

    test "logs the asset, free balance & range when unsuccessful" do
      log_msg =
        capture_log(fn ->
          lock_range(:btc, 1.2, 1.3)
          :timer.sleep(100)
        end)

      assert log_msg =~ ~r/\[lock_range_insufficient_balance:btc,1.1,1.2..1.3\]/
    end
  end

  describe "#unlock" do
    setup [:start_asset_balances]

    test "unlocks the balance for the asset" do
      assert unlock(:btc, 1.0) == :ok

      assert all() == %{
               btc: Tai.Exchanges.AssetBalance.new(2.1, 0.1),
               ltc: Tai.Exchanges.AssetBalance.new(0.1, 0.1)
             }
    end

    test "doesn't unlock the balance if the asset doesn't exist" do
      assert unlock(:xbt, 1.0) == {:error, :not_found}

      assert all() == %{
               btc: Tai.Exchanges.AssetBalance.new(1.1, 1.1),
               ltc: Tai.Exchanges.AssetBalance.new(0.1, 0.1)
             }
    end

    test "doesn't unlock the quantity when there is an insufficient locked balance" do
      assert unlock(:btc, 1.11) == {:error, :insufficient_balance}

      assert all() == %{
               btc: Tai.Exchanges.AssetBalance.new(1.1, 1.1),
               ltc: Tai.Exchanges.AssetBalance.new(0.1, 0.1)
             }
    end

    test "logs the asset & unlocked quantity" do
      log_msg =
        capture_log(fn ->
          unlock(:btc, 1.0)
          :timer.sleep(100)
        end)

      assert log_msg =~ ~r/\[unlock_ok:btc,1.0\]/
    end

    test "logs the asset, locked balance & attempted quantity when there is an insufficent locked balance" do
      log_msg =
        capture_log(fn ->
          unlock(:btc, 1.11)
          :timer.sleep(100)
        end)

      assert log_msg =~ ~r/\[unlock_insufficient_balance:btc,1.1,1.11\]/
    end
  end

  defp all do
    Tai.Exchanges.AssetBalances.all(:my_test_exchange, :my_test_account)
  end

  defp lock_range(asset, min, max) do
    range = Tai.Exchanges.AssetBalanceRange.new(asset, min, max)
    Tai.Exchanges.AssetBalances.lock_range(:my_test_exchange, :my_test_account, range)
  end

  defp unlock(asset, qty) do
    balance_change_request = Tai.Exchanges.AssetBalanceChangeRequest.new(asset, qty)

    Tai.Exchanges.AssetBalances.unlock(
      :my_test_exchange,
      :my_test_account,
      balance_change_request
    )
  end

  defp start_asset_balances(_context) do
    balances = %{
      btc: Tai.Exchanges.AssetBalance.new(1.1, 1.1),
      ltc: Tai.Exchanges.AssetBalance.new(0.1, 0.1)
    }

    start_supervised!({
      Tai.Exchanges.AssetBalances,
      [exchange_id: :my_test_exchange, account_id: :my_test_account, balances: balances]
    })

    :ok
  end
end
