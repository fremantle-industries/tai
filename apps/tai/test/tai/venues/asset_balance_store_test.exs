defmodule Tai.Venues.AssetBalanceStoreTest do
  use ExUnit.Case
  doctest Tai.Venues.AssetBalanceStore

  alias Tai.Venues.AssetBalanceStore

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  describe ".upsert" do
    test "inserts the balance into the ETS table" do
      balance =
        struct(Tai.Venues.AssetBalance, %{
          venue_id: :my_test_exchange,
          account_id: :my_test_account,
          asset: :btc
        })

      assert AssetBalanceStore.upsert(balance) == :ok

      assert [{{:my_test_exchange, :my_test_account, :btc}, ^balance}] =
               :ets.lookup(
                 AssetBalanceStore,
                 {:my_test_exchange, :my_test_account, :btc}
               )
    end

    test "broadcasts an event" do
      Tai.Events.firehose_subscribe()

      balance =
        struct(Tai.Venues.AssetBalance,
          venue_id: :my_test_exchange,
          account_id: :my_test_account,
          asset: :btc,
          free: Decimal.new("0.00000001"),
          locked: Decimal.new(2)
        )

      :ok = AssetBalanceStore.upsert(balance)

      assert_receive {Tai.Event, %Tai.Events.UpsertAssetBalance{} = event, _}
      assert event.venue_id == :my_test_exchange
      assert event.account_id == :my_test_account
      assert event.asset == :btc
      assert event.free == Decimal.new("0.00000001")
      assert event.locked == Decimal.new(2)
    end
  end

  describe ".all" do
    test "returns a list of balances" do
      assert AssetBalanceStore.all() == []

      balance =
        struct(Tai.Venues.AssetBalance,
          venue_id: :my_test_exchange,
          account_id: :my_test_account,
          asset: :btc,
          free: Decimal.new("1.1"),
          locked: Decimal.new("2.1")
        )

      :ok = AssetBalanceStore.upsert(balance)

      assert [^balance] = AssetBalanceStore.all()
    end
  end

  describe ".where" do
    test "returns a list of the matching balances" do
      balance_1 =
        struct(Tai.Venues.AssetBalance, %{
          venue_id: :my_test_exchange,
          account_id: :my_test_account_a,
          asset: :btc,
          free: Decimal.new("1.1")
        })

      balance_2 =
        struct(Tai.Venues.AssetBalance, %{
          venue_id: :my_test_exchange,
          account_id: :my_test_account_b,
          asset: :btc,
          free: Decimal.new("2.1")
        })

      :ok = AssetBalanceStore.upsert(balance_1)
      :ok = AssetBalanceStore.upsert(balance_2)

      assert [^balance_1, ^balance_2] =
               AssetBalanceStore.where(
                 venue_id: :my_test_exchange,
                 asset: :btc
               )
               |> Enum.sort(&(Decimal.cmp(&1.free, &2.free) == :lt))

      assert [^balance_1] =
               AssetBalanceStore.where(
                 venue_id: :my_test_exchange,
                 account_id: :my_test_account_a
               )
    end
  end

  describe ".find_by" do
    test "returns an ok tuple with the balance" do
      balance =
        struct(Tai.Venues.AssetBalance, %{
          venue_id: :my_test_exchange,
          account_id: :my_test_account_a,
          asset: :btc
        })

      :ok = AssetBalanceStore.upsert(balance)

      assert {:ok, ^balance} =
               AssetBalanceStore.find_by(
                 venue_id: :my_test_exchange,
                 account_id: :my_test_account_a
               )
    end

    test "returns an error tuple when not found" do
      assert {:error, :not_found} =
               AssetBalanceStore.find_by(
                 venue_id: :my_test_exchange,
                 account_id: :my_test_account_a
               )
    end
  end

  describe ".lock" do
    setup [:init_asset_balance]

    defp lock(asset, min, max) do
      AssetBalanceStore.lock(%AssetBalanceStore.LockRequest{
        venue_id: :my_test_exchange,
        account_id: :my_test_account,
        asset: asset,
        min: min |> Decimal.cast(),
        max: max |> Decimal.cast()
      })
    end

    test "returns max when = free balance" do
      assert lock(:btc, 0, 2.1) == {:ok, Decimal.new("1.1")}

      assert [balance] = AssetBalanceStore.all()
      assert balance.free == Decimal.new("0.0")
      assert balance.locked == Decimal.new("3.2")
    end

    test "returns max when < free balance" do
      assert lock(:btc, 0, 1.0) == {:ok, Decimal.new("1.0")}

      assert [balance] = AssetBalanceStore.all()
      assert balance.free == Decimal.new("0.1")
      assert balance.locked == Decimal.new("3.1")
    end

    test "returns free balance when max >= free balance and min = free balance" do
      assert lock(:btc, 1.1, 2.2) == {:ok, Decimal.new("1.1")}

      assert [balance] = AssetBalanceStore.all()
      assert balance.free == Decimal.new("0.0")
      assert balance.locked == Decimal.new("3.2")
    end

    test "returns free balance when max >= free balance and min < free balance" do
      assert lock(:btc, 1.0, 2.2) == {:ok, Decimal.new("1.1")}

      assert [balance] = AssetBalanceStore.all()
      assert balance.free == Decimal.new("0.0")
      assert balance.locked == Decimal.new("3.2")
    end

    test "returns an error tuple when the asset doesn't exist" do
      assert lock(:xbt, 0.1, 2.2) == {:error, :not_found}

      assert [balance] = AssetBalanceStore.all()
      assert balance.free == Decimal.new("1.1")
      assert balance.locked == Decimal.new("2.1")
    end

    test "returns an error tuple when min > free balance" do
      assert lock(:btc, 1.11, 2.2) == {:error, {:insufficient_balance, Decimal.new("1.1")}}

      assert [balance] = AssetBalanceStore.all()
      assert balance.free == Decimal.new("1.1")
      assert balance.locked == Decimal.new("2.1")
    end

    test "returns an error tuple when min > max" do
      assert lock(:btc, 0.11, 0.1) == {:error, :min_greater_than_max}

      assert [balance] = AssetBalanceStore.all()
      assert balance.free == Decimal.new("1.1")
      assert balance.locked == Decimal.new("2.1")
    end

    test "returns an error tuple when min < 0" do
      assert lock(:btc, -0.1, 0.1) == {:error, :min_less_than_zero}

      assert [balance] = AssetBalanceStore.all()
      assert balance.free == Decimal.new("1.1")
      assert balance.locked == Decimal.new("2.1")
    end

    test "broadcasts an event when successful" do
      Tai.Events.firehose_subscribe()

      lock(:btc, 0.5, 0.6)

      assert_receive {Tai.Event, %Tai.Events.LockAssetBalanceOk{asset: :btc} = event, _}
      assert event.venue_id == :my_test_exchange
      assert event.account_id == :my_test_account
      assert event.qty == Decimal.new("0.6")
      assert event.min == Decimal.new("0.5")
      assert event.max == Decimal.new("0.6")
    end

    test "broadcasts an event when unsuccessful" do
      Tai.Events.firehose_subscribe()

      lock(:btc, 1.2, 1.3)

      assert_receive {Tai.Event,
                      %Tai.Events.LockAssetBalanceInsufficientFunds{asset: :btc} = event, _}

      assert event.venue_id == :my_test_exchange
      assert event.account_id == :my_test_account
      assert event.min == Decimal.new("1.2")
      assert event.max == Decimal.new("1.3")
      assert event.free == Decimal.new("1.1")
    end
  end

  describe ".unlock" do
    setup [:init_asset_balance]

    defp unlock(asset, qty) do
      AssetBalanceStore.unlock(%AssetBalanceStore.UnlockRequest{
        venue_id: :my_test_exchange,
        account_id: :my_test_account,
        asset: asset,
        qty: qty |> Decimal.cast()
      })
    end

    test "unlocks the balance for the asset" do
      assert unlock(:btc, 1.0) == :ok

      assert [balance] = AssetBalanceStore.all()
      assert balance.free == Decimal.new("2.1")
      assert balance.locked == Decimal.new("1.1")
    end

    test "doesn't unlock the balance if the asset doesn't exist" do
      assert unlock(:xbt, 1.0) == {:error, :not_found}

      assert [balance] = AssetBalanceStore.all()
      assert balance.free == Decimal.new("1.1")
      assert balance.locked == Decimal.new("2.1")
    end

    test "doesn't unlock the quantity when there is an insufficient locked balance" do
      assert unlock(:btc, 2.11) == {:error, {:insufficient_balance, Decimal.new("2.1")}}

      assert [balance] = AssetBalanceStore.all()
      assert balance.free == Decimal.new("1.1")
      assert balance.locked == Decimal.new("2.1")
    end

    test "broadcasts an event when successful" do
      Tai.Events.firehose_subscribe()

      unlock(:btc, 1.0)

      assert_receive {Tai.Event, %Tai.Events.UnlockAssetBalanceOk{asset: :btc} = event, _}
      assert event.venue_id == :my_test_exchange
      assert event.account_id == :my_test_account
      assert event.qty == Decimal.new("1.0")
    end

    test "broadcasts an event when unsuccessful" do
      Tai.Events.firehose_subscribe()

      unlock(:btc, 2.11)

      assert_receive {Tai.Event,
                      %Tai.Events.UnlockAssetBalanceInsufficientFunds{asset: :btc} = event, _}

      assert event.venue_id == :my_test_exchange
      assert event.account_id == :my_test_account
      assert event.locked == Decimal.new("2.1")
      assert event.qty == Decimal.new("2.11")
    end
  end

  describe ".add" do
    setup [:init_asset_balance]

    test "adds to free and returns an ok tuple with the new balance" do
      assert {:ok, balance} =
               AssetBalanceStore.add(
                 :my_test_exchange,
                 :my_test_account,
                 :btc,
                 Decimal.new("0.1")
               )

      assert balance.free == Decimal.new("1.2")
      assert balance.locked == Decimal.new("2.1")

      assert {:ok, balance} =
               AssetBalanceStore.add(:my_test_exchange, :my_test_account, :btc, 0.1)

      assert balance.free == Decimal.new("1.3")
      assert balance.locked == Decimal.new("2.1")

      assert {:ok, balance} =
               AssetBalanceStore.add(
                 :my_test_exchange,
                 :my_test_account,
                 :btc,
                 "0.1"
               )

      assert balance.free == Decimal.new("1.4")
      assert balance.locked == Decimal.new("2.1")
    end

    test "broadcasts an event with the updated balances" do
      Tai.Events.firehose_subscribe()

      AssetBalanceStore.add(:my_test_exchange, :my_test_account, :btc, 0.1)

      assert_receive {Tai.Event, %Tai.Events.AddFreeAssetBalance{asset: :btc} = event, _}
      assert event.venue_id == :my_test_exchange
      assert event.account_id == :my_test_account
      assert event.val == Decimal.new("0.1")
      assert event.free == Decimal.new("1.2")
      assert event.locked == Decimal.new("2.1")
    end

    test "returns an error tuple when the asset doesn't exist" do
      assert AssetBalanceStore.add(:my_test_exchange, :my_test_account, :eth, 0.1) ==
               {:error, :not_found}
    end

    test "returns an error tuple when the value is not positive" do
      assert AssetBalanceStore.add(:my_test_exchange, :my_test_account, :btc, 0) ==
               {:error, :value_must_be_positive}

      assert AssetBalanceStore.add(:my_test_exchange, :my_test_account, :btc, -0.1) ==
               {:error, :value_must_be_positive}
    end
  end

  describe ".sub" do
    setup [:init_asset_balance]

    test "subtracts from free and returns an ok tuple with the new balance" do
      assert {:ok, balance} =
               AssetBalanceStore.sub(
                 :my_test_exchange,
                 :my_test_account,
                 :btc,
                 Decimal.new("0.1")
               )

      assert balance.free == Decimal.new("1.0")
      assert balance.locked == Decimal.new("2.1")

      assert {:ok, balance} =
               AssetBalanceStore.sub(:my_test_exchange, :my_test_account, :btc, 0.1)

      assert balance.free == Decimal.new("0.9")
      assert balance.locked == Decimal.new("2.1")

      assert {:ok, balance} =
               AssetBalanceStore.sub(
                 :my_test_exchange,
                 :my_test_account,
                 :btc,
                 "0.1"
               )

      assert balance.free == Decimal.new("0.8")
      assert balance.locked == Decimal.new("2.1")
    end

    test "broadcasts an event with the updated balances" do
      Tai.Events.firehose_subscribe()

      AssetBalanceStore.sub(:my_test_exchange, :my_test_account, :btc, 0.1)

      assert_receive {Tai.Event, %Tai.Events.SubFreeAssetBalance{asset: :btc} = event, _}
      assert event.venue_id == :my_test_exchange
      assert event.account_id == :my_test_account
      assert event.val == Decimal.new("0.1")
      assert event.free == Decimal.new("1.0")
      assert event.locked == Decimal.new("2.1")
    end

    test "returns an error tuple when the result is less than 0" do
      assert {:ok, _balance} =
               AssetBalanceStore.sub(:my_test_exchange, :my_test_account, :btc, 1.1)

      assert AssetBalanceStore.sub(:my_test_exchange, :my_test_account, :btc, 1.1) ==
               {:error, :result_less_then_zero}
    end

    test "returns an error tuple when the asset doesn't exist" do
      assert AssetBalanceStore.sub(:my_test_exchange, :my_test_account, :eth, 0.1) ==
               {:error, :not_found}
    end

    test "returns an error tuple when the value is not positive" do
      assert AssetBalanceStore.sub(:my_test_exchange, :my_test_account, :btc, 0) ==
               {:error, :value_must_be_positive}

      assert AssetBalanceStore.sub(:my_test_exchange, :my_test_account, :btc, -0.1) ==
               {:error, :value_must_be_positive}
    end
  end

  @free Decimal.new("1.1")
  @locked Decimal.new("2.1")
  defp init_asset_balance(_context) do
    balance =
      struct(Tai.Venues.AssetBalance,
        venue_id: :my_test_exchange,
        account_id: :my_test_account,
        asset: :btc,
        free: @free,
        locked: @locked
      )

    :ok = AssetBalanceStore.upsert(balance)
    {:ok, %{balance: balance}}
  end
end
