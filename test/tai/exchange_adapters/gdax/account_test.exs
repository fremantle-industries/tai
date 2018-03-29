defmodule Tai.ExchangeAdapters.Gdax.AccountTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.ExchangeAdapters.Gdax.Account

  alias Tai.{Exchanges.Account, Trading.OrderResponses}

  setup_all do
    HTTPoison.start()
    start_supervised!({Tai.ExchangeAdapters.Gdax.Account, :my_gdax_exchange})

    :ok
  end

  test "balance returns the USD sum of all accounts" do
    use_cassette "exchange_adapters/gdax/account/balance" do
      # 1337.247745066 USD
      # 1.1 BTC
      # 2.2 LTC
      # 3.3 ETH
      assert Account.balance(:my_gdax_exchange) == Decimal.new("11503.40374506600000000000000")
    end
  end

  test "buy_limit creates an order for the symbol at the given price" do
    use_cassette "exchange_adapters/gdax/account/buy_limit_success" do
      {:ok, order_response} = Account.buy_limit(:my_gdax_exchange, :btcusd, 101.1, 0.2)

      assert order_response.id == "467d09c8-1e41-4e28-8fae-2641182d8d1a"
      assert order_response.status == :pending
      assert %DateTime{} = order_response.created_at
    end
  end

  test "buy_limit returns an {:error, reason} tuple when it can't create the order" do
    use_cassette "exchange_adapters/gdax/account/buy_limit_error" do
      assert Account.buy_limit(:my_gdax_exchange, :btcusd, 101.1, 0.3) == {
               :error,
               %OrderResponses.InsufficientFunds{}
             }
    end
  end

  test "sell_limit creates an order for the symbol at the given price" do
    use_cassette "exchange_adapters/gdax/account/sell_limit_success" do
      {:ok, order_response} = Account.sell_limit(:my_gdax_exchange, :btcusd, 99_999_999.1, 0.2)

      assert order_response.id == "467d09c8-1e41-4e28-8fae-2641182d8d1a"
      assert order_response.status == :pending
      assert %DateTime{} = order_response.created_at
    end
  end

  test "sell_limit returns an {:error, reason} tuple when it can't create the order" do
    use_cassette "exchange_adapters/gdax/account/sell_limit_error" do
      assert Account.sell_limit(:my_gdax_exchange, :btcusd, 99_999_999.1, 0.3) == {
               :error,
               %OrderResponses.InsufficientFunds{}
             }
    end
  end

  test "order_status returns the status" do
    use_cassette "exchange_adapters/gdax/account/order_status_success" do
      {:ok, order_response} = Account.buy_limit(:my_gdax_exchange, :btcusd, 101.1, 0.2)

      assert Account.order_status(:my_gdax_exchange, order_response.id) == {:ok, :open}
    end
  end

  test "order_status returns an error/message tuple when it can't find the order" do
    use_cassette "exchange_adapters/gdax/account/order_status_error" do
      assert Account.order_status(:my_gdax_exchange, "invalid-order-id") ==
               {:error, "Invalid order id"}
    end
  end

  test "cancel_order returns an ok tuple with the order id when it's successfully cancelled" do
    use_cassette "exchange_adapters/gdax/account/cancel_order_success" do
      {:ok, order_response} = Account.buy_limit(:my_gdax_exchange, :btcusd, 101.1, 0.2)
      {:ok, cancelled_order_id} = Account.cancel_order(:my_gdax_exchange, order_response.id)

      assert cancelled_order_id == order_response.id
    end
  end

  test "cancel_order returns an error tuple when it can't cancel the order" do
    use_cassette "exchange_adapters/gdax/account/cancel_order_error" do
      assert Account.cancel_order(:my_gdax_exchange, "invalid-order-id") ==
               {:error, "Invalid order id"}
    end
  end
end
