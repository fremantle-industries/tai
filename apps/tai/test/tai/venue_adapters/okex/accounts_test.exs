defmodule Tai.VenueAdapters.OkEx.AccountsTest do
  use ExUnit.Case, async: false
  import Mock
  alias Tai.VenueAdapters.OkEx

  @credentials %{api_key: "api_key", api_secret: "api_secret"}

  test ".accounts hydrates spot, swap & futures accounts" do
    with_mocks [
      {
        ExOkex.Futures.Private,
        [],
        list_accounts: fn _venue_credentials ->
          accounts = %{"BTC" => %{"equity" => "1.1"}}
          {:ok, %{"info" => accounts}}
        end
      },
      {
        ExOkex.Swap.Private,
        [],
        list_accounts: fn _venue_credentials ->
          accounts = [%{"instrument_id" => "BTC-USD-SWAP", "equity" => "1.2"}]
          {:ok, %{"info" => accounts}}
        end
      },
      {
        ExOkex.Spot.Private,
        [],
        list_accounts: fn _venue_credentials ->
          accounts = [%{"currency" => "BTC", "balance" => "1.3", "available" => "1.0"}]
          {:ok, accounts}
        end
      }
    ] do
      assert {:ok, accounts} = OkEx.Accounts.accounts(:venue_a, :credential_a, @credentials)

      assert Enum.count(accounts) == 3

      assert %Tai.Venues.Account{} = futures_account = Enum.at(accounts, 0)
      assert futures_account.locked == Decimal.new("1.1")
      assert futures_account.type == "futures"

      assert %Tai.Venues.Account{} = swap_account = Enum.at(accounts, 1)
      assert swap_account.locked == Decimal.new("1.2")
      assert swap_account.asset == :btc
      assert swap_account.type == "swap"

      assert %Tai.Venues.Account{} = spot_account = Enum.at(accounts, 2)
      assert spot_account.locked == Decimal.new("0.3")
      assert spot_account.free == Decimal.new("1.0")
      assert spot_account.asset == :btc
      assert spot_account.type == "spot"
    end
  end
end
