defmodule Tai.VenueAdapters.Bitmex.AccountsTest do
  use ExUnit.Case, async: false
  import Mock
  alias Tai.VenueAdapters.Bitmex

  @credentials %{api_key: "api_key", api_secret: "api_secret"}
  @rate_limit struct(ExBitmex.RateLimit)

  test ".accounts normalizes the amount from satoshis to btc" do
    with_mock ExBitmex.Rest.User.Margin,
      get: fn _venue_credentials ->
        wallet = struct(ExBitmex.Margin, currency: "XBt", amount: 133_558_082)
        {:ok, wallet, @rate_limit}
      end do
      assert {:ok, accounts} = Bitmex.Accounts.accounts(:venue_a, :account_a, @credentials)

      assert btc_account = accounts |> hd()
      assert btc_account.locked == Decimal.new("1.33558082")
    end
  end
end
