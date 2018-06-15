defmodule Tai.ExchangeAdapters.Binance.AccountTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.ExchangeAdapters.Binance.Account

  require Logger

  setup_all do
    HTTPoison.start()
    start_supervised!({Tai.ExchangeAdapters.Binance.Account, :my_binance_exchange})

    :ok
  end

  describe "#all_balances" do
    test "returns an error tuple when the secret is invalid" do
      use_cassette "exchange_adapters/binance/account/all_balances_error_invalid_secret" do
        assert Tai.Exchanges.Account.all_balances(:my_binance_exchange) == {
                 :error,
                 %Tai.CredentialError{
                   reason: "API-key format invalid."
                 }
               }
      end
    end

    test "returns an error tuple when the api key is invalid" do
      use_cassette "exchange_adapters/binance/account/all_balances_error_invalid_api_key" do
        assert Tai.Exchanges.Account.all_balances(:my_binance_exchange) == {
                 :error,
                 %Tai.CredentialError{
                   reason: "API-key format invalid."
                 }
               }
      end
    end
  end
end
