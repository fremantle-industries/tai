defmodule Tai.ExchangeAdapters.Gdax.AccountTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.ExchangeAdapters.Gdax.Account

  setup_all do
    HTTPoison.start()
    start_supervised!({Tai.ExchangeAdapters.Gdax.Account, :my_gdax_account})

    :ok
  end

  describe "#all_balances" do
    test "returns an error tuple when the passphrase is invalid" do
      use_cassette "exchange_adapters/gdax/account/all_balances_error_invalid_passphrase" do
        assert Tai.Exchanges.Account.all_balances(:my_gdax_account) == {
                 :error,
                 %Tai.CredentialError{reason: "Invalid Passphrase"}
               }
      end
    end

    test "returns an error tuple when the api key is invalid" do
      use_cassette "exchange_adapters/gdax/account/all_balances_error_invalid_api_key" do
        assert Tai.Exchanges.Account.all_balances(:my_gdax_account) == {
                 :error,
                 %Tai.CredentialError{reason: "Invalid API Key"}
               }
      end
    end

    test "returns an error tuple when down for maintenance" do
      use_cassette "exchange_adapters/gdax/account/all_balances_error_maintenance" do
        assert Tai.Exchanges.Account.all_balances(:my_gdax_account) == {
                 :error,
                 %Tai.ServiceUnavailableError{
                   reason:
                     "GDAX is currently under maintenance. For updates please see https://status.gdax.com/"
                 }
               }
      end
    end
  end

  describe "#buy_limit" do
    test "can create a good til canceled duration order" do
      use_cassette "exchange_adapters/shared/account/gdax/buy_limit_good_til_canceled_success" do
        assert {:ok, %Tai.Trading.OrderResponse{} = response} =
                 :my_gdax_account
                 |> Tai.Exchanges.Account.buy_limit(
                   :btc_usd,
                   101.1,
                   0.2,
                   Tai.Trading.TimeInForce.good_til_canceled()
                 )

        assert response.id != nil
        assert response.status == Tai.Trading.OrderStatus.pending()
        assert response.time_in_force == Tai.Trading.TimeInForce.good_til_canceled()
        assert Decimal.cmp(response.original_size, Decimal.new(0.2)) == :eq
        assert Decimal.cmp(response.executed_size, Decimal.new(0)) == :eq
      end
    end

    test "returns an insufficient funds error tuple" do
      use_cassette "exchange_adapters/shared/account/gdax/buy_limit_error_insufficient_funds" do
        assert {:error, %Tai.Trading.InsufficientBalanceError{}} =
                 :my_gdax_account
                 |> Tai.Exchanges.Account.buy_limit(
                   :btc_usd,
                   101.1,
                   0.3,
                   Tai.Trading.TimeInForce.fill_or_kill()
                 )
      end
    end
  end

  describe "#sell_limit" do
    test "can create a good til canceled duration order" do
      use_cassette "exchange_adapters/shared/account/gdax/sell_limit_good_til_canceled_success" do
        assert {:ok, %Tai.Trading.OrderResponse{} = response} =
                 :my_gdax_account
                 |> Tai.Exchanges.Account.sell_limit(
                   :btc_usd,
                   99_999_999.1,
                   0.2,
                   Tai.Trading.TimeInForce.good_til_canceled()
                 )

        assert response.id != nil
        assert response.status == Tai.Trading.OrderStatus.pending()
        assert response.time_in_force == Tai.Trading.TimeInForce.good_til_canceled()
        assert Decimal.cmp(response.original_size, Decimal.new(0.2)) == :eq
        assert Decimal.cmp(response.executed_size, Decimal.new(0)) == :eq
      end
    end

    test "returns an insufficient funds error tuple" do
      use_cassette "exchange_adapters/shared/account/gdax/sell_limit_error_insufficient_funds" do
        assert {:error, %Tai.Trading.InsufficientBalanceError{}} =
                 :my_gdax_account
                 |> Tai.Exchanges.Account.sell_limit(
                   :btc_usd,
                   99_999_999.1,
                   0.3,
                   Tai.Trading.TimeInForce.good_til_canceled()
                 )
      end
    end
  end

  describe "#order_status" do
    test "returns the status" do
      use_cassette "exchange_adapters/gdax/account/order_status_success" do
        {:ok, order_response} =
          Tai.Exchanges.Account.buy_limit(:my_gdax_account, :btc_usd, 101.1, 0.2)

        assert Tai.Exchanges.Account.order_status(:my_gdax_account, order_response.id) ==
                 {:ok, :open}
      end
    end

    test "returns an error/message tuple when it can't find the order" do
      use_cassette "exchange_adapters/gdax/account/order_status_error" do
        assert Tai.Exchanges.Account.order_status(:my_gdax_account, "invalid-order-id") ==
                 {:error, "Invalid order id"}
      end
    end
  end

  describe "#cancel_order" do
    test "returns an ok tuple with the order id when it's successfully canceled" do
      use_cassette "exchange_adapters/gdax/account/cancel_order_success" do
        {:ok, order_response} =
          Tai.Exchanges.Account.buy_limit(:my_gdax_account, :btc_usd, 101.1, 0.2)

        {:ok, canceled_order_id} =
          Tai.Exchanges.Account.cancel_order(:my_gdax_account, order_response.id)

        assert canceled_order_id == order_response.id
      end
    end

    test "returns an error tuple when it can't cancel the order" do
      use_cassette "exchange_adapters/gdax/account/cancel_order_error" do
        assert Tai.Exchanges.Account.cancel_order(:my_gdax_account, "invalid-order-id") ==
                 {:error, "Invalid order id"}
      end
    end
  end
end
