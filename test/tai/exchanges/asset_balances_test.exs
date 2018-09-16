defmodule Tai.Exchanges.AssetBalancesTest do
  use ExUnit.Case
  doctest Tai.Exchanges.AssetBalances

  import ExUnit.CaptureLog

  setup do
    on_exit(fn ->
      Tai.Exchanges.AssetBalances.clear()
    end)
  end

  describe "#upsert" do
    test "inserts the balance into the ETS table" do
      balance = %Tai.Exchanges.AssetBalance{free: Decimal.new(1), locked: Decimal.new(2)}

      assert Tai.Exchanges.AssetBalances.upsert(
               :my_test_exchange,
               :my_test_account,
               :btc,
               balance
             ) == :ok

      assert [{{:my_test_exchange, :my_test_account, :btc}, ^balance}] =
               :ets.lookup(
                 Tai.Exchanges.AssetBalances,
                 {:my_test_exchange, :my_test_account, :btc}
               )
    end

    test "logs the free & locked balance" do
      log_msg =
        capture_log(fn ->
          balance = %Tai.Exchanges.AssetBalance{free: Decimal.new(1), locked: Decimal.new(2)}

          Tai.Exchanges.AssetBalances.upsert(
            :my_test_exchange,
            :my_test_account,
            :btc,
            balance
          )

          :timer.sleep(100)
        end)

      assert log_msg =~ ~r/\[upsert,my_test_exchange,my_test_account,btc,1,2\]/
    end
  end

  describe "#all" do
    test "returns a map of balances" do
      assert Tai.Exchanges.AssetBalances.all() == %{}

      balance = %Tai.Exchanges.AssetBalance{free: Decimal.new(1.1), locked: Decimal.new(2.1)}

      :ok = Tai.Exchanges.AssetBalances.upsert(:my_test_exchange, :my_test_account, :btc, balance)

      assert %{
               {:my_test_exchange, :my_test_account, :btc} => ^balance
             } = Tai.Exchanges.AssetBalances.all()
    end
  end

  describe "#count" do
    test "returns the number of items in the ETS table" do
      assert Tai.Exchanges.AssetBalances.count() == 0

      init_asset_balance(:ok)

      assert Tai.Exchanges.AssetBalances.count() == 1
    end
  end

  describe "#clear" do
    test "removes the existing items in the ETS table" do
      init_asset_balance(:ok)

      assert Tai.Exchanges.AssetBalances.count() == 1

      assert Tai.Exchanges.AssetBalances.clear() == :ok
      assert Tai.Exchanges.AssetBalances.count() == 0
    end
  end

  describe "#where" do
    test "returns a map of the matching balances" do
      balance_1 = %Tai.Exchanges.AssetBalance{free: Decimal.new(1.1), locked: Decimal.new(2.1)}
      balance_2 = %Tai.Exchanges.AssetBalance{free: Decimal.new(2.1), locked: Decimal.new(3.1)}

      :ok =
        Tai.Exchanges.AssetBalances.upsert(
          :my_test_exchange,
          :my_test_account_a,
          :btc,
          balance_1
        )

      :ok =
        Tai.Exchanges.AssetBalances.upsert(
          :my_test_exchange,
          :my_test_account_b,
          :btc,
          balance_2
        )

      assert %{
               {:my_test_exchange, :my_test_account_a, :btc} => ^balance_1,
               {:my_test_exchange, :my_test_account_b, :btc} => ^balance_2
             } =
               Tai.Exchanges.AssetBalances.where(
                 exchange_id: :my_test_exchange,
                 asset: :btc
               )

      assert %{
               {:my_test_exchange, :my_test_account_a, :btc} => ^balance_1
             } =
               Tai.Exchanges.AssetBalances.where(
                 exchange_id: :my_test_exchange,
                 account_id: :my_test_account_a
               )
    end
  end

  describe "#find_by" do
    test "returns an ok tuple with the key & balance" do
      balance = %Tai.Exchanges.AssetBalance{free: Decimal.new(1.1), locked: Decimal.new(2.1)}

      :ok =
        Tai.Exchanges.AssetBalances.upsert(
          :my_test_exchange,
          :my_test_account_a,
          :btc,
          balance
        )

      assert {
               :ok,
               {{:my_test_exchange, :my_test_account_a, :btc}, ^balance}
             } =
               Tai.Exchanges.AssetBalances.find_by(
                 exchange_id: :my_test_exchange,
                 account_id: :my_test_account_a
               )
    end

    test "returns an error tuple when not found" do
      assert {:error, :not_found} =
               Tai.Exchanges.AssetBalances.find_by(
                 exchange_id: :my_test_exchange,
                 account_id: :my_test_account_a
               )
    end
  end

  describe "#lock_range" do
    setup [:init_asset_balance]

    defp lock_range(asset, min, max) do
      range = Tai.Exchanges.AssetBalanceRange.new(asset, min, max)
      Tai.Exchanges.AssetBalances.lock_range(:my_test_exchange, :my_test_account, range)
    end

    test "returns max when = free balance" do
      assert lock_range(:btc, 0, 2.1) == {:ok, Decimal.new(1.1)}

      assert Tai.Exchanges.AssetBalances.all() == %{
               {:my_test_exchange, :my_test_account, :btc} =>
                 Tai.Exchanges.AssetBalance.new(0.0, 3.2)
             }
    end

    test "returns max when < free balance" do
      assert lock_range(:btc, 0, 1.0) == {:ok, Decimal.new(1.0)}

      assert Tai.Exchanges.AssetBalances.all() == %{
               {:my_test_exchange, :my_test_account, :btc} =>
                 Tai.Exchanges.AssetBalance.new(0.1, 3.1)
             }
    end

    test "returns free balance when max >= free balance and min = free balance" do
      assert lock_range(:btc, 1.1, 2.2) == {:ok, Decimal.new(1.1)}

      assert Tai.Exchanges.AssetBalances.all() == %{
               {:my_test_exchange, :my_test_account, :btc} =>
                 Tai.Exchanges.AssetBalance.new(0.0, 3.2)
             }
    end

    test "returns free balance when max >= free balance and min < free balance" do
      assert lock_range(:btc, 1.0, 2.2) == {:ok, Decimal.new(1.1)}

      assert Tai.Exchanges.AssetBalances.all() == %{
               {:my_test_exchange, :my_test_account, :btc} =>
                 Tai.Exchanges.AssetBalance.new(0.0, 3.2)
             }
    end

    test "returns an error tuple when the asset doesn't exist" do
      assert lock_range(:xbt, 0.1, 2.2) == {:error, :not_found}

      assert Tai.Exchanges.AssetBalances.all() == %{
               {:my_test_exchange, :my_test_account, :btc} =>
                 Tai.Exchanges.AssetBalance.new(1.1, 2.1)
             }
    end

    test "returns an error tuple when min > free balance" do
      assert lock_range(:btc, 1.11, 2.2) == {:error, :insufficient_balance}

      assert Tai.Exchanges.AssetBalances.all() == %{
               {:my_test_exchange, :my_test_account, :btc} =>
                 Tai.Exchanges.AssetBalance.new(1.1, 2.1)
             }
    end

    test "returns an error tuple when min > max" do
      assert lock_range(:btc, 0.11, 0.1) == {:error, :min_greater_than_max}

      assert Tai.Exchanges.AssetBalances.all() == %{
               {:my_test_exchange, :my_test_account, :btc} =>
                 Tai.Exchanges.AssetBalance.new(1.1, 2.1)
             }
    end

    test "returns an error tuple when min < 0" do
      assert lock_range(:btc, -0.1, 0.1) == {:error, :min_less_than_zero}

      assert Tai.Exchanges.AssetBalances.all() == %{
               {:my_test_exchange, :my_test_account, :btc} =>
                 Tai.Exchanges.AssetBalance.new(1.1, 2.1)
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
    setup [:init_asset_balance]

    defp unlock(asset, qty) do
      balance_change_request = Tai.Exchanges.AssetBalanceChangeRequest.new(asset, qty)

      Tai.Exchanges.AssetBalances.unlock(
        :my_test_exchange,
        :my_test_account,
        balance_change_request
      )
    end

    test "unlocks the balance for the asset" do
      assert unlock(:btc, 1.0) == :ok

      assert Tai.Exchanges.AssetBalances.all() == %{
               {:my_test_exchange, :my_test_account, :btc} =>
                 Tai.Exchanges.AssetBalance.new(2.1, 1.1)
             }
    end

    test "doesn't unlock the balance if the asset doesn't exist" do
      assert unlock(:xbt, 1.0) == {:error, :not_found}

      assert Tai.Exchanges.AssetBalances.all() == %{
               {:my_test_exchange, :my_test_account, :btc} =>
                 Tai.Exchanges.AssetBalance.new(1.1, 2.1)
             }
    end

    test "doesn't unlock the quantity when there is an insufficient locked balance" do
      assert unlock(:btc, 2.11) == {:error, :insufficient_balance}

      assert Tai.Exchanges.AssetBalances.all() == %{
               {:my_test_exchange, :my_test_account, :btc} =>
                 Tai.Exchanges.AssetBalance.new(1.1, 2.1)
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
          unlock(:btc, 2.11)
          :timer.sleep(100)
        end)

      assert log_msg =~ ~r/\[unlock_insufficient_balance:btc,2.1,2.11\]/
    end
  end

  describe "#add" do
    setup [:init_asset_balance]

    test "adds to free and returns an ok tuple with the new balance" do
      assert {:ok, balance} =
               Tai.Exchanges.AssetBalances.add(
                 :my_test_exchange,
                 :my_test_account,
                 :btc,
                 Decimal.new(0.1)
               )

      assert balance.free == Decimal.new(1.2)
      assert balance.locked == Decimal.new(2.1)

      assert {:ok, balance} =
               Tai.Exchanges.AssetBalances.add(:my_test_exchange, :my_test_account, :btc, 0.1)

      assert balance.free == Decimal.new(1.3)
      assert balance.locked == Decimal.new(2.1)

      assert {:ok, balance} =
               Tai.Exchanges.AssetBalances.add(
                 :my_test_exchange,
                 :my_test_account,
                 :btc,
                 "0.1"
               )

      assert balance.free == Decimal.new(1.4)
      assert balance.locked == Decimal.new(2.1)
    end

    test "logs the updated free balance" do
      log_msg =
        capture_log(fn ->
          Tai.Exchanges.AssetBalances.add(:my_test_exchange, :my_test_account, :btc, 0.1)
          :timer.sleep(100)
        end)

      assert log_msg =~ ~r/\[add:btc,0.1,1.2,2.1\]/
    end

    test "returns an error tuple when the asset doesn't exist" do
      assert Tai.Exchanges.AssetBalances.add(:my_test_exchange, :my_test_account, :eth, 0.1) ==
               {:error, :not_found}
    end

    test "returns an error tuple when the value is not positive" do
      assert Tai.Exchanges.AssetBalances.add(:my_test_exchange, :my_test_account, :btc, 0) ==
               {:error, :value_must_be_positive}

      assert Tai.Exchanges.AssetBalances.add(:my_test_exchange, :my_test_account, :btc, -0.1) ==
               {:error, :value_must_be_positive}
    end
  end

  describe "#sub" do
    setup [:init_asset_balance]

    test "subtracts from free and returns an ok tuple with the new balance" do
      assert {:ok, balance} =
               Tai.Exchanges.AssetBalances.sub(
                 :my_test_exchange,
                 :my_test_account,
                 :btc,
                 Decimal.new(0.1)
               )

      assert balance.free == Decimal.new(1.0)
      assert balance.locked == Decimal.new(2.1)

      assert {:ok, balance} =
               Tai.Exchanges.AssetBalances.sub(:my_test_exchange, :my_test_account, :btc, 0.1)

      assert balance.free == Decimal.new(0.9)
      assert balance.locked == Decimal.new(2.1)

      assert {:ok, balance} =
               Tai.Exchanges.AssetBalances.sub(
                 :my_test_exchange,
                 :my_test_account,
                 :btc,
                 "0.1"
               )

      assert balance.free == Decimal.new(0.8)
      assert balance.locked == Decimal.new(2.1)
    end

    test "logs the updated free balance" do
      log_msg =
        capture_log(fn ->
          Tai.Exchanges.AssetBalances.sub(:my_test_exchange, :my_test_account, :btc, 0.1)
          :timer.sleep(100)
        end)

      assert log_msg =~ ~r/\[sub:btc,0.1,1.0,2.1\]/
    end

    test "returns an error tuple when the result is less than 0" do
      assert {:ok, _balance} =
               Tai.Exchanges.AssetBalances.sub(:my_test_exchange, :my_test_account, :btc, 1.1)

      assert Tai.Exchanges.AssetBalances.sub(:my_test_exchange, :my_test_account, :btc, 1.1) ==
               {:error, :result_less_then_zero}
    end

    test "returns an error tuple when the asset doesn't exist" do
      assert Tai.Exchanges.AssetBalances.sub(:my_test_exchange, :my_test_account, :eth, 0.1) ==
               {:error, :not_found}
    end

    test "returns an error tuple when the value is not positive" do
      assert Tai.Exchanges.AssetBalances.sub(:my_test_exchange, :my_test_account, :btc, 0) ==
               {:error, :value_must_be_positive}

      assert Tai.Exchanges.AssetBalances.sub(:my_test_exchange, :my_test_account, :btc, -0.1) ==
               {:error, :value_must_be_positive}
    end
  end

  @free Decimal.new(1.1)
  @locked Decimal.new(2.1)
  defp init_asset_balance(_context) do
    balance = %Tai.Exchanges.AssetBalance{free: @free, locked: @locked}

    :ok = Tai.Exchanges.AssetBalances.upsert(:my_test_exchange, :my_test_account, :btc, balance)

    {:ok, %{balance: balance}}
  end
end
