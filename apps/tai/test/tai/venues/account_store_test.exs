defmodule Tai.Venues.AccountStoreTest do
  use ExUnit.Case, async: false
  doctest Tai.Venues.AccountStore

  alias Tai.Venues.AccountStore

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  describe ".upsert" do
    test "inserts the account into the ETS table" do
      key = {:my_test_exchange, :my_test_credential, :btc, :spot}

      account =
        struct(Tai.Venues.Account, %{
          venue_id: :my_test_exchange,
          credential_id: :my_test_credential,
          asset: :btc,
          type: :spot
        })

      assert AccountStore.upsert(account) == :ok
      assert [{returned_key, returned_account}] = :ets.lookup(AccountStore, key)
      assert returned_key == key
      assert returned_account == account
    end
  end

  describe ".all" do
    test "returns a list of accounts" do
      assert AccountStore.all() == []

      account =
        struct(Tai.Venues.Account,
          venue_id: :my_test_exchange,
          credential_id: :my_test_credential,
          asset: :btc,
          free: Decimal.new("1.1"),
          locked: Decimal.new("2.1")
        )

      assert AccountStore.upsert(account) == :ok

      accounts = AccountStore.all()
      assert Enum.count(accounts) == 1
      assert Enum.at(accounts, 0) == account
    end
  end

  describe ".where" do
    test "returns a list of the matching accounts" do
      account_1 =
        struct(Tai.Venues.Account, %{
          venue_id: :my_test_exchange,
          credential_id: :my_test_credential_a,
          asset: :btc,
          free: Decimal.new("1.1")
        })

      account_2 =
        struct(Tai.Venues.Account, %{
          venue_id: :my_test_exchange,
          credential_id: :my_test_credential_b,
          asset: :btc,
          free: Decimal.new("2.1")
        })

      assert AccountStore.upsert(account_1) == :ok
      assert AccountStore.upsert(account_2) == :ok

      accounts =
        AccountStore.where(venue_id: :my_test_exchange, asset: :btc)
        |> Enum.sort(&(Decimal.cmp(&1.free, &2.free) == :lt))

      assert Enum.count(accounts) == 2
      assert Enum.at(accounts, 0) == account_1
      assert Enum.at(accounts, 1) == account_2

      accounts =
        AccountStore.where(venue_id: :my_test_exchange, credential_id: :my_test_credential_a)

      assert Enum.count(accounts) == 1
      assert Enum.at(accounts, 0) == account_1
    end
  end

  describe ".find_by" do
    test "returns an ok tuple with the account" do
      account =
        struct(Tai.Venues.Account, %{
          venue_id: :venue_a,
          credential_id: :credential_a,
          asset: :btc
        })

      assert AccountStore.upsert(account) == :ok

      assert {:ok, found_account} =
               AccountStore.find_by(
                 venue_id: :venue_a,
                 credential_id: :credential_a
               )

      assert found_account == account
    end

    test "returns an error tuple when not found" do
      assert AccountStore.find_by(
               venue_id: :venue_a,
               credential_id: :credential_a
             ) == {:error, :not_found}
    end
  end

  describe ".lock" do
    setup [:init_account]

    defp lock(asset, min, max) do
      AccountStore.lock(%AccountStore.LockRequest{
        venue_id: :my_test_exchange,
        credential_id: :my_test_credential,
        asset: asset,
        min: min |> Decimal.cast(),
        max: max |> Decimal.cast()
      })
    end

    test "returns max when = free balance" do
      assert lock(:btc, 0, 2.1) == {:ok, Decimal.new("1.1")}

      assert [account] = AccountStore.all()
      assert account.free == Decimal.new("0.0")
      assert account.locked == Decimal.new("3.2")
    end

    test "returns max when < free balance" do
      assert lock(:btc, 0, 1.0) == {:ok, Decimal.new("1.0")}

      assert [account] = AccountStore.all()
      assert account.free == Decimal.new("0.1")
      assert account.locked == Decimal.new("3.1")
    end

    test "returns free balance when max >= free balance and min = free balance" do
      assert lock(:btc, 1.1, 2.2) == {:ok, Decimal.new("1.1")}

      assert [account] = AccountStore.all()
      assert account.free == Decimal.new("0.0")
      assert account.locked == Decimal.new("3.2")
    end

    test "returns free balance when max >= free balance and min < free balance" do
      assert lock(:btc, 1.0, 2.2) == {:ok, Decimal.new("1.1")}

      assert [account] = AccountStore.all()
      assert account.free == Decimal.new("0.0")
      assert account.locked == Decimal.new("3.2")
    end

    test "returns an error tuple when the asset doesn't exist" do
      assert lock(:xbt, 0.1, 2.2) == {:error, :not_found}

      assert [account] = AccountStore.all()
      assert account.free == Decimal.new("1.1")
      assert account.locked == Decimal.new("2.1")
    end

    test "returns an error tuple when min > free balance" do
      assert lock(:btc, 1.11, 2.2) == {:error, {:insufficient_balance, Decimal.new("1.1")}}

      assert [account] = AccountStore.all()
      assert account.free == Decimal.new("1.1")
      assert account.locked == Decimal.new("2.1")
    end

    test "returns an error tuple when min > max" do
      assert lock(:btc, 0.11, 0.1) == {:error, :min_greater_than_max}

      assert [account] = AccountStore.all()
      assert account.free == Decimal.new("1.1")
      assert account.locked == Decimal.new("2.1")
    end

    test "returns an error tuple when min < 0" do
      assert lock(:btc, -0.1, 0.1) == {:error, :min_less_than_zero}

      assert [account] = AccountStore.all()
      assert account.free == Decimal.new("1.1")
      assert account.locked == Decimal.new("2.1")
    end

    test "broadcasts an event when successful" do
      Tai.Events.firehose_subscribe()

      lock(:btc, 0.5, 0.6)

      assert_receive {Tai.Event, %Tai.Events.LockAccountOk{asset: :btc} = event, _}
      assert event.venue_id == :my_test_exchange
      assert event.credential_id == :my_test_credential
      assert event.qty == Decimal.new("0.6")
      assert event.min == Decimal.new("0.5")
      assert event.max == Decimal.new("0.6")
    end

    test "broadcasts an event when unsuccessful" do
      Tai.Events.firehose_subscribe()

      lock(:btc, 1.2, 1.3)

      assert_receive {Tai.Event, %Tai.Events.LockAccountInsufficientFunds{asset: :btc} = event, _}

      assert event.venue_id == :my_test_exchange
      assert event.credential_id == :my_test_credential
      assert event.min == Decimal.new("1.2")
      assert event.max == Decimal.new("1.3")
      assert event.free == Decimal.new("1.1")
    end
  end

  describe ".unlock" do
    setup [:init_account]

    defp unlock(asset, qty) do
      AccountStore.unlock(%AccountStore.UnlockRequest{
        venue_id: :my_test_exchange,
        credential_id: :my_test_credential,
        asset: asset,
        qty: qty |> Decimal.cast()
      })
    end

    test "unlocks the balance for the asset" do
      assert unlock(:btc, 1.0) == :ok

      assert [account] = AccountStore.all()
      assert account.free == Decimal.new("2.1")
      assert account.locked == Decimal.new("1.1")
    end

    test "doesn't unlock the balance if the asset doesn't exist" do
      assert unlock(:xbt, 1.0) == {:error, :not_found}

      assert [account] = AccountStore.all()
      assert account.free == Decimal.new("1.1")
      assert account.locked == Decimal.new("2.1")
    end

    test "doesn't unlock the quantity when there is an insufficient locked balance" do
      assert unlock(:btc, 2.11) == {:error, {:insufficient_balance, Decimal.new("2.1")}}

      assert [account] = AccountStore.all()
      assert account.free == Decimal.new("1.1")
      assert account.locked == Decimal.new("2.1")
    end

    test "broadcasts an event when successful" do
      Tai.Events.firehose_subscribe()

      unlock(:btc, 1.0)

      assert_receive {Tai.Event, %Tai.Events.UnlockAccountOk{asset: :btc} = event, _}
      assert event.venue_id == :my_test_exchange
      assert event.credential_id == :my_test_credential
      assert event.qty == Decimal.new("1.0")
    end

    test "broadcasts an event when unsuccessful" do
      Tai.Events.firehose_subscribe()

      unlock(:btc, 2.11)

      assert_receive {Tai.Event, %Tai.Events.UnlockAccountInsufficientFunds{asset: :btc} = event,
                      _}

      assert event.venue_id == :my_test_exchange
      assert event.credential_id == :my_test_credential
      assert event.locked == Decimal.new("2.1")
      assert event.qty == Decimal.new("2.11")
    end
  end

  describe ".add" do
    setup [:init_account]

    test "adds to free and returns an ok tuple with the new balance" do
      assert {:ok, account} =
               AccountStore.add(
                 :my_test_exchange,
                 :my_test_credential,
                 :btc,
                 Decimal.new("0.1")
               )

      assert account.free == Decimal.new("1.2")
      assert account.locked == Decimal.new("2.1")

      assert {:ok, account} = AccountStore.add(:my_test_exchange, :my_test_credential, :btc, 0.1)

      assert account.free == Decimal.new("1.3")
      assert account.locked == Decimal.new("2.1")

      assert {:ok, account} =
               AccountStore.add(
                 :my_test_exchange,
                 :my_test_credential,
                 :btc,
                 "0.1"
               )

      assert account.free == Decimal.new("1.4")
      assert account.locked == Decimal.new("2.1")
    end

    test "broadcasts an event with the updated balances" do
      Tai.Events.firehose_subscribe()

      AccountStore.add(:my_test_exchange, :my_test_credential, :btc, 0.1)

      assert_receive {Tai.Event, %Tai.Events.AddFreeAccount{asset: :btc} = event, _}
      assert event.venue_id == :my_test_exchange
      assert event.credential_id == :my_test_credential
      assert event.val == Decimal.new("0.1")
      assert event.free == Decimal.new("1.2")
      assert event.locked == Decimal.new("2.1")
    end

    test "returns an error tuple when the asset doesn't exist" do
      assert AccountStore.add(:my_test_exchange, :my_test_credential, :eth, 0.1) ==
               {:error, :not_found}
    end

    test "returns an error tuple when the value is not positive" do
      assert AccountStore.add(:my_test_exchange, :my_test_credential, :btc, 0) ==
               {:error, :value_must_be_positive}

      assert AccountStore.add(:my_test_exchange, :my_test_credential, :btc, -0.1) ==
               {:error, :value_must_be_positive}
    end
  end

  describe ".sub" do
    setup [:init_account]

    test "subtracts from free and returns an ok tuple with the new balance" do
      assert {:ok, account} =
               AccountStore.sub(
                 :my_test_exchange,
                 :my_test_credential,
                 :btc,
                 Decimal.new("0.1")
               )

      assert account.free == Decimal.new("1.0")
      assert account.locked == Decimal.new("2.1")

      assert {:ok, account} = AccountStore.sub(:my_test_exchange, :my_test_credential, :btc, 0.1)

      assert account.free == Decimal.new("0.9")
      assert account.locked == Decimal.new("2.1")

      assert {:ok, account} =
               AccountStore.sub(
                 :my_test_exchange,
                 :my_test_credential,
                 :btc,
                 "0.1"
               )

      assert account.free == Decimal.new("0.8")
      assert account.locked == Decimal.new("2.1")
    end

    test "broadcasts an event with the updated balances" do
      Tai.Events.firehose_subscribe()

      AccountStore.sub(:my_test_exchange, :my_test_credential, :btc, 0.1)

      assert_receive {Tai.Event, %Tai.Events.SubFreeAccount{asset: :btc} = event, _}
      assert event.venue_id == :my_test_exchange
      assert event.credential_id == :my_test_credential
      assert event.val == Decimal.new("0.1")
      assert event.free == Decimal.new("1.0")
      assert event.locked == Decimal.new("2.1")
    end

    test "returns an error tuple when the result is less than 0" do
      assert {:ok, _balance} = AccountStore.sub(:my_test_exchange, :my_test_credential, :btc, 1.1)

      assert AccountStore.sub(:my_test_exchange, :my_test_credential, :btc, 1.1) ==
               {:error, :result_less_then_zero}
    end

    test "returns an error tuple when the asset doesn't exist" do
      assert AccountStore.sub(:my_test_exchange, :my_test_credential, :eth, 0.1) ==
               {:error, :not_found}
    end

    test "returns an error tuple when the value is not positive" do
      assert AccountStore.sub(:my_test_exchange, :my_test_credential, :btc, 0) ==
               {:error, :value_must_be_positive}

      assert AccountStore.sub(:my_test_exchange, :my_test_credential, :btc, -0.1) ==
               {:error, :value_must_be_positive}
    end
  end

  @free Decimal.new("1.1")
  @locked Decimal.new("2.1")
  defp init_account(_context) do
    account =
      struct(Tai.Venues.Account,
        venue_id: :my_test_exchange,
        credential_id: :my_test_credential,
        asset: :btc,
        free: @free,
        locked: @locked
      )

    :ok = AccountStore.upsert(account)
    {:ok, %{account: account}}
  end
end
