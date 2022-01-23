defmodule Tai.Venues.AccountStoreTest do
  use Tai.TestSupport.DataCase, async: false

  @venue :venue_a

  test "broadcasts a message after the record is stored" do
    :ok = Tai.SystemBus.subscribe(:account_store)
    account = struct(Tai.Venues.Account, venue_id: @venue)

    assert {:ok, _} = Tai.Venues.AccountStore.put(account)
    assert_receive {:account_store, :after_put, stored_account}

    accounts = Tai.Venues.AccountStore.all()
    assert Enum.count(accounts) == 1
    assert Enum.member?(accounts, account)
    assert stored_account == account
  end
end
