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
end
