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

  describe ".create_order buy limit" do
    test "can create a gtc order" do
      use_cassette "exchange_adapters/shared/account/gdax/buy_limit_good_till_cancel_success" do
        assert {:ok, %Tai.Trading.OrderResponse{} = response} =
                 Tai.Trading.Order
                 |> struct(%{
                   exchange_id: :my_gdax_exchange,
                   account_id: :test,
                   side: :buy,
                   type: :limit,
                   symbol: :btc_usd,
                   price: Decimal.new("101.1"),
                   size: Decimal.new("0.2"),
                   time_in_force: :gtc
                 })
                 |> Tai.Exchanges.Account.create_order()

        assert response.id != nil
        assert response.status == :pending
        assert response.time_in_force == :gtc
        assert Decimal.cmp(response.original_size, Decimal.new("0.2")) == :eq
        assert Decimal.cmp(response.executed_size, Decimal.new(0)) == :eq
      end
    end

    test "returns an insufficient funds error tuple" do
      use_cassette "exchange_adapters/shared/account/gdax/buy_limit_error_insufficient_funds" do
        assert {:error, %Tai.Trading.InsufficientBalanceError{}} =
                 Tai.Trading.Order
                 |> struct(%{
                   exchange_id: :my_gdax_exchange,
                   account_id: :test,
                   side: :buy,
                   type: :limit,
                   symbol: :btc_usd,
                   price: Decimal.new("101.1"),
                   size: Decimal.new("0.3"),
                   time_in_force: :gtc
                 })
                 |> Tai.Exchanges.Account.create_order()
      end
    end
  end

  describe ".create_order sell limit" do
    test "can create a gtc order" do
      use_cassette "exchange_adapters/shared/account/gdax/sell_limit_good_till_cancel_success" do
        assert {:ok, %Tai.Trading.OrderResponse{} = response} =
                 Tai.Trading.Order
                 |> struct(%{
                   exchange_id: :my_gdax_exchange,
                   account_id: :test,
                   side: :sell,
                   type: :limit,
                   symbol: :btc_usd,
                   price: Decimal.new("99999999.1"),
                   size: Decimal.new("0.2"),
                   time_in_force: :gtc
                 })
                 |> Tai.Exchanges.Account.create_order()

        assert response.id != nil
        assert response.status == :pending
        assert response.time_in_force == :gtc
        assert Decimal.cmp(response.original_size, Decimal.new("0.2")) == :eq
        assert Decimal.cmp(response.executed_size, Decimal.new(0)) == :eq
      end
    end

    test "returns an insufficient funds error tuple" do
      use_cassette "exchange_adapters/shared/account/gdax/sell_limit_error_insufficient_funds" do
        assert {:error, %Tai.Trading.InsufficientBalanceError{}} =
                 Tai.Trading.Order
                 |> struct(%{
                   exchange_id: :my_gdax_exchange,
                   account_id: :test,
                   side: :sell,
                   type: :limit,
                   symbol: :btc_usd,
                   price: Decimal.new("99999999.1"),
                   size: Decimal.new("0.3"),
                   time_in_force: :gtc
                 })
                 |> Tai.Exchanges.Account.create_order()
      end
    end
  end

  describe ".order_status" do
    test "returns the status" do
      use_cassette "exchange_adapters/gdax/account/order_status_success" do
        {:ok, order_response} =
          Tai.Trading.Order
          |> struct(%{
            exchange_id: :my_gdax_exchange,
            account_id: :test,
            side: :buy,
            type: :limit,
            symbol: :btc_usd,
            price: Decimal.new("101.1"),
            size: Decimal.new("0.2"),
            time_in_force: :gtc
          })
          |> Tai.Exchanges.Account.create_order()

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

  describe ".cancel_order" do
    test "returns an ok tuple with the order id when it's successfully canceled" do
      use_cassette "exchange_adapters/gdax/account/cancel_order_success" do
        {:ok, order_response} =
          Tai.Trading.Order
          |> struct(%{
            exchange_id: :my_gdax_exchange,
            account_id: :test,
            side: :buy,
            type: :limit,
            symbol: :btc_usd,
            price: Decimal.new("101.1"),
            size: Decimal.new("0.2"),
            time_in_force: :gtc
          })
          |> Tai.Exchanges.Account.create_order()

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
