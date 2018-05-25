defmodule Tai.ExchangeAdapters.Binance.AccountTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.ExchangeAdapters.Binance.Account

  alias Tai.{Exchanges.Account, CredentialError}

  setup_all do
    HTTPoison.start()
    start_supervised!({Tai.ExchangeAdapters.Binance.Account, :my_binance_exchange})

    :ok
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
end
