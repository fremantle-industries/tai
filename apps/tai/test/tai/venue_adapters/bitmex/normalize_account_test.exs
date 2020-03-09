defmodule Tai.VenueAdapters.Bitmex.NormalizeAccountTest do
  use ExUnit.Case, async: true
  alias Tai.VenueAdapters.Bitmex

  @venue :venue_a
  @credential :credential_a

  test ".satoshis_to_btc/1 converts satoshis to bitcoin and returns the result as a decimal" do
    assert Bitmex.NormalizeAccount.satoshis_to_btc(10_000_000) == Decimal.new("0.1")
    assert Bitmex.NormalizeAccount.satoshis_to_btc(Decimal.new("20000000")) == Decimal.new("0.2")
  end

  test ".build/3 returns an account struct for Xbt from the margin response" do
    margin = struct(ExBitmex.Margin, currency: "XBt", amount: 900_000_000)

    assert {:ok, account} = Bitmex.NormalizeAccount.build(margin, @venue, @credential)
    assert account.asset == :btc
    assert account.equity == Decimal.new("9")
    assert account.locked == Decimal.new("9")
    assert account.free == Decimal.new("0")
  end

  test ".build/3 returns an error when the currency is not supported" do
    margin = struct(ExBitmex.Margin, currency: "not-supported", amount: 900_000_000)

    assert {:error, reason} = Bitmex.NormalizeAccount.build(margin, @venue, @credential)
    assert reason == {:unsupported_currency, "not-supported"}
  end
end
