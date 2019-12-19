defmodule Tai.VenueAdapters.OkEx.AssetBalancesTest do
  use ExUnit.Case, async: false
  import Mock
  alias Tai.VenueAdapters.OkEx

  @credentials %{api_key: "api_key", api_secret: "api_secret"}

  test ".asset_balances hydrates spot, swap & futures balances" do
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
      assert {:ok, balances} =
               OkEx.AssetBalances.asset_balances(:venue_a, :account_a, @credentials)

      assert Enum.count(balances) == 3

      assert %Tai.Venues.AssetBalance{} = futures_balance = Enum.at(balances, 0)
      assert futures_balance.locked == Decimal.new("1.1")
      assert futures_balance.type == "futures"

      assert %Tai.Venues.AssetBalance{} = swap_balance = Enum.at(balances, 1)
      assert swap_balance.locked == Decimal.new("1.2")
      assert swap_balance.asset == :btc
      assert swap_balance.type == "swap"

      assert %Tai.Venues.AssetBalance{} = spot_balance = Enum.at(balances, 2)
      assert spot_balance.locked == Decimal.new("0.3")
      assert spot_balance.free == Decimal.new("1.0")
      assert spot_balance.asset == :btc
      assert spot_balance.type == "spot"
    end
  end
end
