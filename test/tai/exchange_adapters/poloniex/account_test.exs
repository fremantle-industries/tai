defmodule Tai.ExchangeAdapters.Poloniex.AccountTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.ExchangeAdapters.Poloniex.Account

  setup_all do
    HTTPoison.start()
    Confex.resolve_env!(:ex_poloniex)

    start_supervised!(
      {Tai.ExchangeAdapters.Poloniex.Account,
       [exchange_id: :my_poloniex_exchange, account_id: :test, credentials: %{}]}
    )

    :ok
  end

  describe ".create_order buy limit" do
    setup do
      order =
        struct(Tai.Trading.Order, %{
          exchange_id: :my_poloniex_exchange,
          account_id: :test,
          side: :buy,
          type: :limit,
          symbol: :ltcbtc,
          price: Decimal.new("0.0001"),
          size: Decimal.new("1"),
          time_in_force: :fok
        })

      {:ok, %{order: order}}
    end

    test "fill or kill returns an error tuple when it can't completely execute a fill or kill order",
         %{order: order} do
      use_cassette "exchange_adapters/poloniex/account/buy_limit_fill_or_kill_error_unable_to_fill_completely" do
        assert Tai.Exchanges.Account.create_order(order) == {
                 :error,
                 %Tai.Trading.FillOrKillError{
                   reason: %ExPoloniex.FillOrKillError{
                     message: "Unable to fill order completely."
                   }
                 }
               }
      end
    end

    test "returns an error tuple when the request times out", %{order: order} do
      use_cassette "exchange_adapters/poloniex/account/buy_limit_error_timeout" do
        assert Tai.Exchanges.Account.create_order(order) == {:error, :timeout}
      end
    end

    test "returns an error tuple when the api key is invalid", %{order: order} do
      use_cassette "exchange_adapters/poloniex/account/buy_limit_error_invalid_api_key" do
        assert Tai.Exchanges.Account.create_order(order) == {
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
        order =
          struct(Tai.Trading.Order, %{
            exchange_id: :my_poloniex_exchange,
            account_id: :test,
            side: :buy,
            type: :limit,
            symbol: :ltcbtc,
            price: Decimal.new("0.02"),
            size: Decimal.new("1"),
            time_in_force: :fok
          })

        assert Tai.Exchanges.Account.create_order(order) == {
                 :error,
                 %Tai.Trading.InsufficientBalanceError{
                   reason: %ExPoloniex.NotEnoughError{message: "Not enough BTC."}
                 }
               }
      end
    end
  end
end
