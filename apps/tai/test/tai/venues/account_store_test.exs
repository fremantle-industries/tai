defmodule Tai.Venues.AccountStoreTest do
  use ExUnit.Case, async: false

  @test_store_id __MODULE__
  @venue :venue_a
  @credential :main
  @asset :btc
  @account_type "default"

  setup do
    start_supervised!({Tai.SystemBus, 1})
    start_supervised!({Tai.Venues.AccountStore, id: @test_store_id})

    :ok
  end

  test "broadcasts a message namespaced to the venue/credential/asset/type after it's stored" do
    Tai.SystemBus.subscribe({:account_store, {@venue, @credential, @asset, @account_type}})

    account =
      struct(Tai.Venues.Account,
        venue_id: @venue,
        credential_id: @credential,
        asset: @asset,
        type: @account_type
      )

    assert {:ok, _} = Tai.Venues.AccountStore.put(account, @test_store_id)
    assert_receive {:account_store, :after_put, stored_account}

    accounts = Tai.Venues.AccountStore.all(@test_store_id)
    assert Enum.count(accounts) == 1
    assert Enum.member?(accounts, account)
    assert stored_account == account
  end
end
