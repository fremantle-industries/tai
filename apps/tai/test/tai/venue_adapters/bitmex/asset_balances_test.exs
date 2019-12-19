defmodule Tai.VenueAdapters.Bitmex.AssetBalancesTest do
  use ExUnit.Case, async: false
  import Mock
  alias Tai.VenueAdapters.Bitmex

  @credentials %{api_key: "api_key", api_secret: "api_secret"}
  @rate_limit struct(ExBitmex.RateLimit)

  test ".asset_balances normalizes the amount from satoshis to btc" do
    with_mock ExBitmex.Rest.User.Wallet,
      get: fn _venue_credentials ->
        wallet = struct(ExBitmex.Wallet, currency: "XBt", amount: 133_558_082)
        {:ok, wallet, @rate_limit}
      end do
      assert {:ok, balances} =
               Bitmex.AssetBalances.asset_balances(:venue_a, :account_a, @credentials)

      assert btc_balance = balances |> hd()
      assert btc_balance.locked == Decimal.new("1.33558082")
    end
  end
end
