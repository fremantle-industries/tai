defmodule Tai.ExchangeAdapters.BitstampTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.ExchangeAdapters.Bitstamp

  setup_all do
    HTTPoison.start
    ExVCR.Config.cassette_library_dir("test/fixture/vcr_cassettes/exchanges/adapters/bitstamp")
  end

  test "price returns the value of the last trade for the symbol" do
    use_cassette "price_success" do
      assert Tai.ExchangeAdapters.Bitstamp.price(:btcusd) == {:ok, Decimal.new(15243.98)}
    end
  end

  test "price supports upper and lower case symbols" do
    use_cassette "price_success" do
      assert Tai.ExchangeAdapters.Bitstamp.price(:BtcusD) == {:ok, Decimal.new(15243.98)}
    end
  end

  test "price returns an error/message tuple when the symbol doesn't exist" do
    use_cassette "price_not_found" do
      assert Tai.ExchangeAdapters.Bitstamp.price(:idontexist) == {:error, "not found"}
    end
  end

  test "balance returns the USD sum of all accounts" do
    use_cassette "balance_success" do
      assert Tai.ExchangeAdapters.Bitstamp.balance == Decimal.new("14349.6900000000000")
    end
  end

  test "buy_limit creates an order for the symbol at the given price" do
    use_cassette "buy_limit_success" do
      {:ok, order_response} = Tai.ExchangeAdapters.Bitstamp.buy_limit(:btcusd, 101.1, 0.1)

      assert order_response.id == 674873684
      assert order_response.status == :pending
    end
  end

  test "buy_limit returns an error/details tuple when it can't create the order" do
    use_cassette "buy_limit_error" do
      {:error, message} = Tai.ExchangeAdapters.Bitstamp.buy_limit(:btcusd, 101.1, 0.2)

      assert message == %{"__all__" => ["You need 20.27 USD to open that order. You have only 0.82 USD available. Check your account balance for details."]}
    end
  end

  test "sell_limit creates an order for the symbol at the given price" do
    use_cassette "sell_limit_success" do
      {:ok, order_response} = Tai.ExchangeAdapters.Bitstamp.sell_limit(:btcusd, 99_999.01, 0.01)

      assert order_response.id == 680258903
      assert order_response.status == :pending
    end
  end

  test "sell_limit returns an error/details tuple when it can't create the order" do
    use_cassette "sell_limit_error" do
      {:error, message} = Tai.ExchangeAdapters.Bitstamp.sell_limit(:btcusd, 99_999.01, 0.2)

      assert message == %{"__all__" => ["You have only 0.01000000 BTC available. Check your account balance for details."]}
    end
  end

  test "order_status returns the status" do
    use_cassette "order_status_success" do
      {:ok, order_response} = Tai.ExchangeAdapters.Bitstamp.buy_limit(:btcusd, 101.1, 0.1)

      assert Tai.ExchangeAdapters.Bitstamp.order_status(order_response.id) == {:ok, :open}
    end
  end

  test "order_status returns an error/reason tuple when it can't find the order" do
    use_cassette "order_status_not_found" do
      assert Tai.ExchangeAdapters.Bitstamp.order_status(1234) == {:error, "Order not found."}
    end
  end

  test "cancel_order returns an ok tuple with the order id when it's successfully cancelled" do
    use_cassette "cancel_order_success" do
      {:ok, order_response} = Tai.ExchangeAdapters.Bitstamp.buy_limit(:btcusd, 101.1, 0.1)
      {:ok, cancelled_order_id} = Tai.ExchangeAdapters.Bitstamp.cancel_order(order_response.id)

      assert cancelled_order_id == order_response.id
    end
  end

  test "cancel_order returns an error tuple when it can't cancel the order" do
    use_cassette "cancel_order_error" do
      {:error, message} = Tai.ExchangeAdapters.Bitstamp.cancel_order("invalid-order-id")

      assert message == "Invalid order id"
    end
  end
end
