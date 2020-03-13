defmodule Tai.Venues.AccountStoreTest do
  use ExUnit.Case, async: false

  @test_store_id __MODULE__
  @venue :venue_a

  setup do
    start_supervised!({Tai.SystemBus, 1})
    start_supervised!({Tai.Venues.AccountStore, id: @test_store_id})

    :ok
  end

  test "broadcasts a message after the record is stored" do
    Tai.SystemBus.subscribe(:account_store)
    account = struct(Tai.Venues.Account, venue_id: @venue)

    assert {:ok, _} = Tai.Venues.AccountStore.put(account, @test_store_id)
    assert_receive {:account_store, :after_put, stored_account}

    accounts = Tai.Venues.AccountStore.all(@test_store_id)
    assert Enum.count(accounts) == 1
    assert Enum.member?(accounts, account)
    assert stored_account == account
  end
end
