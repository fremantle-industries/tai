defmodule Tai.ExchangeAdapters.Gdax.AccountTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.ExchangeAdapters.Gdax.Account

  alias Tai.{Exchanges.Account, CredentialError, Trading.OrderResponses}

  setup_all do
    HTTPoison.start()
    start_supervised!({Tai.ExchangeAdapters.Gdax.Account, :my_gdax_exchange})

    :ok
  end

  describe "#all_balances" do
    test "returns an error tuple when the passphrase is invalid" do
      use_cassette "exchange_adapters/gdax/account/all_balances_error_invalid_passphrase" do
        assert Account.all_balances(:my_gdax_exchange) == {
                 :error,
                 %CredentialError{reason: "Invalid Passphrase"}
               }
      end
    end

    test "returns an error tuple when the api key is invalid" do
      use_cassette "exchange_adapters/gdax/account/all_balances_error_invalid_api_key" do
        assert Account.all_balances(:my_gdax_exchange) == {
                 :error,
                 %CredentialError{reason: "Invalid API Key"}
               }
      end
    end
  end

  describe "#buy_limit" do
    test "creates an order for the symbol at the given price" do
      use_cassette "exchange_adapters/gdax/account/buy_limit_success" do
        {:ok, order_response} = Account.buy_limit(:my_gdax_exchange, :btcusd, 101.1, 0.2)

        assert order_response.id == "467d09c8-1e41-4e28-8fae-2641182d8d1a"
        assert order_response.status == :pending
        assert %DateTime{} = order_response.created_at
      end
    end

    test "returns an {:error, reason} tuple when it can't create the order" do
      use_cassette "exchange_adapters/gdax/account/buy_limit_error" do
        assert Account.buy_limit(:my_gdax_exchange, :btcusd, 101.1, 0.3) == {
                 :error,
                 %OrderResponses.InsufficientFunds{}
               }
      end
    end
  end

  describe "#sell_limit" do
    test "creates an order for the symbol at the given price" do
      use_cassette "exchange_adapters/gdax/account/sell_limit_success" do
        {:ok, order_response} = Account.sell_limit(:my_gdax_exchange, :btcusd, 99_999_999.1, 0.2)

        assert order_response.id == "467d09c8-1e41-4e28-8fae-2641182d8d1a"
        assert order_response.status == :pending
        assert %DateTime{} = order_response.created_at
      end
    end

    test "returns an {:error, reason} tuple when it can't create the order" do
      use_cassette "exchange_adapters/gdax/account/sell_limit_error" do
        assert Account.sell_limit(:my_gdax_exchange, :btcusd, 99_999_999.1, 0.3) == {
                 :error,
                 %OrderResponses.InsufficientFunds{}
               }
      end
    end
  end

  describe "#order_status" do
    test "returns the status" do
      use_cassette "exchange_adapters/gdax/account/order_status_success" do
        {:ok, order_response} = Account.buy_limit(:my_gdax_exchange, :btcusd, 101.1, 0.2)

        assert Account.order_status(:my_gdax_exchange, order_response.id) == {:ok, :open}
      end
    end

    test "returns an error/message tuple when it can't find the order" do
      use_cassette "exchange_adapters/gdax/account/order_status_error" do
        assert Account.order_status(:my_gdax_exchange, "invalid-order-id") ==
                 {:error, "Invalid order id"}
      end
    end
  end

  describe "#cancel_order" do
    test "returns an ok tuple with the order id when it's successfully cancelled" do
      use_cassette "exchange_adapters/gdax/account/cancel_order_success" do
        {:ok, order_response} = Account.buy_limit(:my_gdax_exchange, :btcusd, 101.1, 0.2)
        {:ok, cancelled_order_id} = Account.cancel_order(:my_gdax_exchange, order_response.id)

        assert cancelled_order_id == order_response.id
      end
    end

    test "returns an error tuple when it can't cancel the order" do
      use_cassette "exchange_adapters/gdax/account/cancel_order_error" do
        assert Account.cancel_order(:my_gdax_exchange, "invalid-order-id") ==
                 {:error, "Invalid order id"}
      end
    end
  end
end
