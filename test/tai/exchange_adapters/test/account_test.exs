defmodule Tai.ExchangeAdapters.Test.AccountTest do
  use ExUnit.Case, async: true
  doctest Tai.ExchangeAdapters.Test.Account

  alias Tai.Exchanges.Account

  setup_all do
    start_supervised!({Tai.ExchangeAdapters.Test.Account, :my_test_account})

    :ok
  end

  test "all_balances returns an ok tuple with a map of symbols and their balances for the account" do
    assert Account.all_balances(:my_test_account) == {
             :ok,
             %{
               bch: Decimal.new(0),
               btc: Decimal.new("1.8122774027894548"),
               eth: Decimal.new("0.000000000000200000000"),
               ltc: Decimal.new("0.03")
             }
           }
  end

  test "buy_limit returns an unknown error tuple when it can't find a match" do
    assert Account.buy_limit(:my_test_account, :btcusd, 101.1, 0.1) == {:error, :unknown_error}
  end

  test "sell_limit returns an unknown error tuple when it can't find a match" do
    assert Account.sell_limit(:my_test_account, :btcusd, 101.1, 0.1) == {:error, :unknown_error}
  end
end
