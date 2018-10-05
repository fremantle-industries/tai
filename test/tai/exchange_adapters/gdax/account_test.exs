defmodule Tai.ExchangeAdapters.Gdax.AccountTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.ExchangeAdapters.Gdax.Account

  setup_all do
    HTTPoison.start()

    credentials = %{
      api_url: "https://api-public.sandbox.pro.coinbase.com",
      api_key: System.get_env("GDAX_API_KEY"),
      api_secret: System.get_env("GDAX_API_SECRET"),
      api_passphrase: System.get_env("GDAX_API_PASSPHRASE")
    }

    start_supervised!(
      {Tai.ExchangeAdapters.Gdax.Account,
       [exchange_id: :my_gdax_exchange, account_id: :test, credentials: credentials]}
    )

    :ok
  end

  describe "#buy_limit" do
    test "can create a good till cancel duration order" do
      use_cassette "exchange_adapters/shared/account/gdax/buy_limit_good_till_cancel_success" do
        assert {:ok, %Tai.Trading.OrderResponse{} = response} =
                 Tai.Exchanges.Account.buy_limit(
                   :my_gdax_exchange,
                   :test,
                   :btc_usd,
                   101.1,
                   0.2,
                   Tai.Trading.TimeInForce.good_till_cancel()
                 )

        assert response.id != nil
        assert response.status == Tai.Trading.OrderStatus.pending()
        assert response.time_in_force == Tai.Trading.TimeInForce.good_till_cancel()
        assert Decimal.cmp(response.original_size, Decimal.new(0.2)) == :eq
        assert Decimal.cmp(response.executed_size, Decimal.new(0)) == :eq
      end
    end

    test "returns an insufficient funds error tuple" do
      use_cassette "exchange_adapters/shared/account/gdax/buy_limit_error_insufficient_funds" do
        assert {:error, %Tai.Trading.InsufficientBalanceError{}} =
                 Tai.Exchanges.Account.buy_limit(
                   :my_gdax_exchange,
                   :test,
                   :btc_usd,
                   101.1,
                   0.3,
                   Tai.Trading.TimeInForce.fill_or_kill()
                 )
      end
    end
  end

  describe "#sell_limit" do
    test "can create a good till cancel duration order" do
      use_cassette "exchange_adapters/shared/account/gdax/sell_limit_good_till_cancel_success" do
        assert {:ok, %Tai.Trading.OrderResponse{} = response} =
                 Tai.Exchanges.Account.sell_limit(
                   :my_gdax_exchange,
                   :test,
                   :btc_usd,
                   99_999_999.1,
                   0.2,
                   Tai.Trading.TimeInForce.good_till_cancel()
                 )

        assert response.id != nil
        assert response.status == Tai.Trading.OrderStatus.pending()
        assert response.time_in_force == Tai.Trading.TimeInForce.good_till_cancel()
        assert Decimal.cmp(response.original_size, Decimal.new(0.2)) == :eq
        assert Decimal.cmp(response.executed_size, Decimal.new(0)) == :eq
      end
    end

    test "returns an insufficient funds error tuple" do
      use_cassette "exchange_adapters/shared/account/gdax/sell_limit_error_insufficient_funds" do
        assert {:error, %Tai.Trading.InsufficientBalanceError{}} =
                 Tai.Exchanges.Account.sell_limit(
                   :my_gdax_exchange,
                   :test,
                   :btc_usd,
                   99_999_999.1,
                   0.3,
                   Tai.Trading.TimeInForce.good_till_cancel()
                 )
      end
    end
  end

  describe "#order_status" do
    test "returns the status" do
      use_cassette "exchange_adapters/gdax/account/order_status_success" do
        {:ok, order_response} =
          Tai.Exchanges.Account.buy_limit(:my_gdax_exchange, :test, :btc_usd, 101.1, 0.2)

        assert Tai.Exchanges.Account.order_status(:my_gdax_exchange, :test, order_response.id) ==
                 {:ok, :open}
      end
    end

    test "returns an error/message tuple when it can't find the order" do
      use_cassette "exchange_adapters/gdax/account/order_status_error" do
        assert Tai.Exchanges.Account.order_status(:my_gdax_exchange, :test, "invalid-order-id") ==
                 {:error, "Invalid order id"}
      end
    end
  end

  describe "#cancel_order" do
    test "returns an ok tuple with the order id when it's successfully canceled" do
      use_cassette "exchange_adapters/gdax/account/cancel_order_success" do
        {:ok, order_response} =
          Tai.Exchanges.Account.buy_limit(:my_gdax_exchange, :test, :btc_usd, 101.1, 0.2)

        {:ok, canceled_order_id} =
          Tai.Exchanges.Account.cancel_order(:my_gdax_exchange, :test, order_response.id)

        assert canceled_order_id == order_response.id
      end
    end

    test "returns an error tuple when it can't cancel the order" do
      use_cassette "exchange_adapters/gdax/account/cancel_order_error" do
        assert Tai.Exchanges.Account.cancel_order(:my_gdax_exchange, :test, "invalid-order-id") ==
                 {:error, "Invalid order id"}
      end
    end
  end
end
