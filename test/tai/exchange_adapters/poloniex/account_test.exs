defmodule Tai.ExchangeAdapters.Poloniex.AccountTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.ExchangeAdapters.Poloniex.Account

  alias Tai.{Exchanges.Account, CredentialError, TimeoutError}
  alias Tai.Trading.OrderDurations.{FillOrKill}
  alias Tai.Trading.{FillOrKillError, OrderResponse}

  setup_all do
    HTTPoison.start()
    start_supervised!({Tai.ExchangeAdapters.Poloniex.Account, :my_poloniex_exchange})

    :ok
  end

  test "all_balances returns an ok tuple with a map of balances by symbol" do
    use_cassette "exchange_adapters/poloniex/account/all_balances_success" do
      assert {:ok, %{} = balances} = Account.all_balances(:my_poloniex_exchange)

      assert balances[:btc] == Decimal.new("0.00128767")
      assert balances[:eth] == Decimal.new("0.00000000")
      assert balances[:ltc] == Decimal.new("0.92999800")
      assert balances[:bch] == Decimal.new("0.00000000")
      assert balances[:usdt] == Decimal.new("0.00000000")
    end
  end

  test "all_balances returns an error tuple when the secret is invalid" do
    use_cassette "exchange_adapters/poloniex/account/all_balances_error_invalid_secret" do
      assert Account.all_balances(:my_poloniex_exchange) == {
               :error,
               %CredentialError{
                 reason: %ExPoloniex.AuthenticationError{message: "Invalid API key/secret pair."}
               }
             }
    end
  end

  test "all_balances returns an error tuple when the api key is invalid" do
    use_cassette "exchange_adapters/poloniex/account/all_balances_error_invalid_api_key" do
      assert Account.all_balances(:my_poloniex_exchange) == {
               :error,
               %CredentialError{
                 reason: %ExPoloniex.AuthenticationError{message: "Invalid API key/secret pair."}
               }
             }
    end
  end

  test "all_balances returns an error tuple when the request times out" do
    use_cassette "exchange_adapters/poloniex/account/all_balances_error_timeout" do
      assert Account.all_balances(:my_poloniex_exchange) == {
               :error,
               %TimeoutError{reason: %HTTPoison.Error{reason: "timeout"}}
             }
    end
  end

  test "buy_limit can create a fill or kill order" do
    use_cassette "exchange_adapters/poloniex/account/buy_limit_fill_or_kill_success" do
      assert {:ok, %OrderResponse{} = response} =
               Account.buy_limit(:my_poloniex_exchange, :ltcbtc, 0.0165, 0.01, %FillOrKill{})

      assert response.id == "174286166423"
    end
  end

  test "buy_limit with fill or kill returns an error tuple when it can't completely execute a fill or kill order" do
    use_cassette "exchange_adapters/poloniex/account/buy_limit_fill_or_kill_error_unable_to_fill_completely" do
      assert Account.buy_limit(:my_poloniex_exchange, :ltcbtc, 0.0001, 1, %FillOrKill{}) == {
               :error,
               %FillOrKillError{
                 reason: %ExPoloniex.FillOrKillError{message: "Unable to fill order completely."}
               }
             }
    end
  end

  test "buy_limit with fill or kill returns an error tuple when the request times out" do
    use_cassette "exchange_adapters/poloniex/account/buy_limit_fill_or_kill_error_timeout" do
      assert Account.buy_limit(:my_poloniex_exchange, :ltcbtc, 0.0001, 1, %FillOrKill{}) == {
               :error,
               %TimeoutError{reason: %HTTPoison.Error{reason: "timeout"}}
             }
    end
  end

  test "buy_limit with fill or kill returns an error tuple when the api key is invalid" do
    use_cassette "exchange_adapters/poloniex/account/buy_limit_fill_or_kill_error_invalid_api_key" do
      assert Account.buy_limit(:my_poloniex_exchange, :ltcbtc, 0.0001, 1, %FillOrKill{}) == {
               :error,
               %Tai.CredentialError{
                 reason: %ExPoloniex.AuthenticationError{message: "Invalid API key/secret pair."}
               }
             }
    end
  end
end
