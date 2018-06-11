defmodule Tai.ExchangeAdapters.Poloniex.AccountTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.ExchangeAdapters.Poloniex.Account

  setup_all do
    HTTPoison.start()
    start_supervised!({Tai.ExchangeAdapters.Poloniex.Account, :my_poloniex_exchange})

    :ok
  end

  describe "#all_balances" do
    test "returns an error tuple when the secret is invalid" do
      use_cassette "exchange_adapters/poloniex/account/all_balances_error_invalid_secret" do
        assert Tai.Exchanges.Account.all_balances(:my_poloniex_exchange) == {
                 :error,
                 %Tai.CredentialError{
                   reason: %ExPoloniex.AuthenticationError{
                     message: "Invalid API key/secret pair."
                   }
                 }
               }
      end
    end

    test "returns an error tuple when the api key is invalid" do
      use_cassette "exchange_adapters/poloniex/account/all_balances_error_invalid_api_key" do
        assert Tai.Exchanges.Account.all_balances(:my_poloniex_exchange) == {
                 :error,
                 %Tai.CredentialError{
                   reason: %ExPoloniex.AuthenticationError{
                     message: "Invalid API key/secret pair."
                   }
                 }
               }
      end
    end
  end

  describe "#buy_limit" do
    test "fill or kill returns an error tuple when it can't completely execute a fill or kill order" do
      use_cassette "exchange_adapters/poloniex/account/buy_limit_fill_or_kill_error_unable_to_fill_completely" do
        assert Tai.Exchanges.Account.buy_limit(
                 :my_poloniex_exchange,
                 :ltcbtc,
                 0.0001,
                 1,
                 Tai.Trading.TimeInForce.fill_or_kill()
               ) == {
                 :error,
                 %Tai.Trading.FillOrKillError{
                   reason: %ExPoloniex.FillOrKillError{
                     message: "Unable to fill order completely."
                   }
                 }
               }
      end
    end

    test "returns an error tuple when the request times out" do
      use_cassette "exchange_adapters/poloniex/account/buy_limit_error_timeout" do
        assert Tai.Exchanges.Account.buy_limit(
                 :my_poloniex_exchange,
                 :ltcbtc,
                 0.0001,
                 1,
                 Tai.Trading.TimeInForce.fill_or_kill()
               ) == {
                 :error,
                 %Tai.TimeoutError{reason: %HTTPoison.Error{reason: "timeout"}}
               }
      end
    end

    test "returns an error tuple when the api key is invalid" do
      use_cassette "exchange_adapters/poloniex/account/buy_limit_error_invalid_api_key" do
        assert Tai.Exchanges.Account.buy_limit(
                 :my_poloniex_exchange,
                 :ltcbtc,
                 0.0001,
                 1,
                 Tai.Trading.TimeInForce.fill_or_kill()
               ) == {
                 :error,
                 %Tai.CredentialError{
                   reason: %ExPoloniex.AuthenticationError{
                     message: "Invalid API key/secret pair."
                   }
                 }
               }
      end
    end

    test "returns an error tuple when it doesn't have enough of a balance" do
      use_cassette "exchange_adapters/poloniex/account/buy_limit_error_not_enough" do
        assert Tai.Exchanges.Account.buy_limit(
                 :my_poloniex_exchange,
                 :ltcbtc,
                 0.02,
                 1000,
                 Tai.Trading.TimeInForce.fill_or_kill()
               ) == {
                 :error,
                 %Tai.Trading.InsufficientBalanceError{
                   reason: %ExPoloniex.NotEnoughError{message: "Not enough BTC."}
                 }
               }
      end
    end
  end
end
