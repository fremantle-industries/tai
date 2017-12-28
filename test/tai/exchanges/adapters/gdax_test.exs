defmodule Tai.Exchanges.Adapters.GdaxTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.Exchanges.Adapters.Gdax

  setup_all do
    HTTPoison.start
    ExVCR.Config.cassette_library_dir("test/fixture/vcr_cassettes/exchanges/adapters/gdax")
  end

  test "price returns value of the last trade for the symbol" do
    use_cassette "price_success" do
      assert Tai.Exchanges.Adapters.Gdax.price(:btcusd) == {:ok, Decimal.new("152.18000000")}
    end
  end

  test "price supports upper and lower case symbols" do
    use_cassette "price_success" do
      assert Tai.Exchanges.Adapters.Gdax.price(:BtcusD) == {:ok, Decimal.new("152.18000000")}
    end
  end

  test "price returns an error/message tuple when the symbol is not found" do
    use_cassette "price_not_found" do
      assert Tai.Exchanges.Adapters.Gdax.price(:idontexist) == {:error, "not found"}
    end
  end

  test "balance returns the USD sum of all accounts" do
    use_cassette "balance" do
      # 1337.247745066 USD
      # 1.1 BTC
      # 2.2 LTC
      # 3.3 ETH
      assert Tai.Exchanges.Adapters.Gdax.balance == Decimal.new("11503.40374506600000000000000")
    end
  end

  test "quotes returns a bid/ask tuple for the given symbol" do
    use_cassette "quotes_success" do
      {:ok, bid, ask} = Tai.Exchanges.Adapters.Gdax.quotes(:btcusd)

      assert bid.size == Decimal.new(0.05)
      assert bid.price == Decimal.new(8015.01)
      assert ask.size == Decimal.new(4.222)
      assert ask.price == Decimal.new(8019.87)
    end
  end

  test "quotes returns an error tuple with a message when it can't find the symbol" do
    use_cassette "quotes_error" do
      {:error, message} = Tai.Exchanges.Adapters.Gdax.quotes(:notfound)

      assert message == "NotFound"
    end
  end

  test "buy_limit creates an order for the symbol at the given price" do
    use_cassette "buy_limit_success" do
      {:ok, order_response} = Tai.Exchanges.Adapters.Gdax.buy_limit(:btcusd, 101.1, 0.2)

      assert order_response.id == "467d09c8-1e41-4e28-8fae-2641182d8d1a"
      assert order_response.status == :pending
    end
  end

  test "buy_limit returns an error/message tuple when it can't create the order" do
    use_cassette "buy_limit_error" do
      {:error, message} = Tai.Exchanges.Adapters.Gdax.buy_limit(:btcusd, 101.1, 0.3)

      assert message == "Insufficient funds"
    end
  end

  test "sell_limit creates an order for the symbol at the given price" do
    use_cassette "sell_limit_success" do
      {:ok, order_response} = Tai.Exchanges.Adapters.Gdax.sell_limit(:btcusd, 99_999_999.1, 0.2)

      assert order_response.id == "467d09c8-1e41-4e28-8fae-2641182d8d1a"
      assert order_response.status == :pending
    end
  end

  test "sell_limit returns an error tuple with a message when it can't create the order" do
    use_cassette "sell_limit_error" do
      {:error, message} = Tai.Exchanges.Adapters.Gdax.sell_limit(:btcusd, 99_999_999.1, 0.3)

      assert message == "Insufficient funds"
    end
  end

  test "order_status returns the status" do
    use_cassette "order_status_success" do
      {:ok, order_response} = Tai.Exchanges.Adapters.Gdax.buy_limit(:btcusd, 101.1, 0.2)
      {:ok, status} = Tai.Exchanges.Adapters.Gdax.order_status(order_response.id)

      assert status == :open
    end
  end

  test "order_status returns an error tuple with a message when it can't find the order" do
    use_cassette "order_status_error" do
      {:error, message} = Tai.Exchanges.Adapters.Gdax.order_status("invalid-order-id")

      assert message == "Invalid order id"
    end
  end

  test "cancel_order returns an ok tuple with the order id when it's successfully cancelled" do
    use_cassette "cancel_order_success" do
      {:ok, order_response} = Tai.Exchanges.Adapters.Gdax.buy_limit(:btcusd, 101.1, 0.2)
      {:ok, cancelled_order_id} = Tai.Exchanges.Adapters.Gdax.cancel_order(order_response.id)

      assert cancelled_order_id == order_response.id
    end
  end

  test "cancel_order returns an error tuple when it can't cancel the order" do
    use_cassette "cancel_order_error" do
      {:error, message} = Tai.Exchanges.Adapters.Gdax.cancel_order("invalid-order-id")

      assert message == "Invalid order id"
    end
  end
end
