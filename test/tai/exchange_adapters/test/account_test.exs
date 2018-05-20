defmodule Tai.ExchangeAdapters.Test.AccountTest do
  use ExUnit.Case, async: true
  doctest Tai.ExchangeAdapters.Test.Account

  alias Tai.Exchanges.Account

  setup_all do
    start_supervised!({Tai.ExchangeAdapters.Test.Account, :my_test_account})

    :ok
  end

  test "buy_limit returns an unknown error tuple when it can't find a match" do
    assert Account.buy_limit(:my_test_account, :btcusd, 101.1, 0.1) == {:error, :unknown_error}
  end

  test "sell_limit returns an unknown error tuple when it can't find a match" do
    assert Account.sell_limit(:my_test_account, :btcusd, 101.1, 0.1) == {:error, :unknown_error}
  end
end
