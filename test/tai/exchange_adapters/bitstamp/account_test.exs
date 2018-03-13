defmodule Tai.ExchangeAdapters.Bitstamp.AccountTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.ExchangeAdapters.Bitstamp.Account

  alias Tai.Exchanges.Account

  setup_all do
    HTTPoison.start
    ExVCR.Config.cassette_library_dir("test/fixture/vcr_cassettes/exchanges/adapters/bitstamp/account")
    start_supervised!({Tai.ExchangeAdapters.Bitstamp.Account, :my_bitstamp_exchange})

    :ok
  end

  test "buy_limit creates an order for the symbol at the given price" do
    use_cassette "buy_limit_success" do
      {:ok, order_response} = Account.buy_limit(:my_bitstamp_exchange, :btcusd, 101.1, 0.1)

      assert order_response.id == "674873684"
      assert order_response.status == :pending
      assert %DateTime{} = order_response.created_at
    end
  end

  test "buy_limit returns an error/details tuple when it can't create the order" do
    use_cassette "buy_limit_error" do
      {:error, message} = Account.buy_limit(:my_bitstamp_exchange, :btcusd, 101.1, 0.2)

      assert message == %{"__all__" => ["You need 20.27 USD to open that order. You have only 0.82 USD available. Check your account balance for details."]}
    end
  end

  test "sell_limit creates an order for the symbol at the given price" do
    use_cassette "sell_limit_success" do
      {:ok, order_response} = Account.sell_limit(:my_bitstamp_exchange, :btcusd, 99_999.01, 0.01)

      assert order_response.id == "680258903"
      assert order_response.status == :pending
      assert %DateTime{} = order_response.created_at
    end
  end

  test "sell_limit returns an error/details tuple when it can't create the order" do
    use_cassette "sell_limit_error" do
      {:error, message} = Account.sell_limit(:my_bitstamp_exchange, :btcusd, 99_999.01, 0.2)

      assert message == %{"__all__" => ["You have only 0.01000000 BTC available. Check your account balance for details."]}
    end
  end

  test "order_status returns the status" do
    use_cassette "order_status_success" do
      {:ok, order_response} = Account.buy_limit(:my_bitstamp_exchange, :btcusd, 101.1, 0.1)

      assert Account.order_status(:my_bitstamp_exchange, order_response.id) == {:ok, :open}
    end
  end

  test "order_status returns an error/reason tuple when it can't find the order" do
    use_cassette "order_status_not_found" do
      assert Account.order_status(:my_bitstamp_exchange, 1234) == {:error, "Order not found."}
    end
  end

  test "cancel_order returns an ok tuple with the order id when it's successfully cancelled" do
    use_cassette "cancel_order_success" do
      {:ok, order_response} = Account.buy_limit(:my_bitstamp_exchange, :btcusd, 101.1, 0.1)
      {:ok, cancelled_order_id} = Account.cancel_order(:my_bitstamp_exchange, order_response.id)

      assert cancelled_order_id == order_response.id
    end
  end

  test "cancel_order returns an error tuple when it can't cancel the order" do
    use_cassette "cancel_order_error" do
      {:error, message} = Account.cancel_order(:my_bitstamp_exchange, "invalid-order-id")

      assert message == "Invalid order id"
    end
  end
end
