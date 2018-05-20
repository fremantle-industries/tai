defmodule Tai.ExchangeAdapters.Binance.AccountTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.ExchangeAdapters.Binance.Account

  alias Tai.{Exchanges.Account, CredentialError, TimeoutError}

  setup_all do
    HTTPoison.start()
    start_supervised!({Tai.ExchangeAdapters.Binance.Account, :my_binance_exchange})

    :ok
  end

  test "all_balances returns an ok tuple with a map of balances by symbol" do
    use_cassette "exchange_adapters/binance/account/all_balances_success" do
      assert {:ok, %{} = balances} = Account.all_balances(:my_binance_exchange)

      assert balances[:btc] == Decimal.new("0.00000000")
      assert balances[:bts] == Decimal.new("9787.04310000")
    end
  end

  test "all_balances returns an error tuple when the secret is invalid" do
    use_cassette "exchange_adapters/binance/account/all_balances_error_invalid_secret" do
      assert Account.all_balances(:my_binance_exchange) == {
               :error,
               %CredentialError{
                 reason: "API-key format invalid."
               }
             }
    end
  end

  test "all_balances returns an error tuple when the api key is invalid" do
    use_cassette "exchange_adapters/binance/account/all_balances_error_invalid_api_key" do
      assert Account.all_balances(:my_binance_exchange) == {
               :error,
               %CredentialError{
                 reason: "API-key format invalid."
               }
             }
    end
  end

  test "all_balances returns an error tuple when the request times out" do
    use_cassette "exchange_adapters/binance/account/all_balances_error_timeout" do
      assert Account.all_balances(:my_binance_exchange) == {
               :error,
               %TimeoutError{reason: %HTTPoison.Error{reason: "timeout"}}
             }
    end
  end
end
