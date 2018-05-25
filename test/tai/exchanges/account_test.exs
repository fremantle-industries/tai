defmodule Tai.Exchanges.AccountTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.Exchanges.Account

  alias Tai.TimeoutError
  alias Tai.Exchanges.Account
  alias Tai.Trading.{OrderResponses, Order, OrderStatus}

  defp my_adapter(adapter_id), do: :"my_#{adapter_id}_account"

  # Test adapter would need to make HTTP requests for the shared test cases to 
  # work. This may be a good reason to use EchoBoy instead of matching on 
  # special symbols
  @adapters [
    {Tai.ExchangeAdapters.Binance.Account, :binance},
    {Tai.ExchangeAdapters.Gdax.Account, :gdax},
    {Tai.ExchangeAdapters.Poloniex.Account, :poloniex}
  ]
  setup_all do
    HTTPoison.start()

    @adapters
    |> Enum.map(fn {adapter, adapter_id} -> {adapter, my_adapter(adapter_id)} end)
    |> Enum.map(&start_supervised!/1)

    :ok
  end

  describe "#all_balances" do
    @adapters
    |> Enum.map(fn {_, adapter_id} ->
      @adapter_id adapter_id
      test "#{adapter_id} adapter returns a map of assets" do
        use_cassette "exchange_adapters/shared/account/#{@adapter_id}/all_balances_success" do
          assert {:ok, balances} = @adapter_id |> my_adapter |> Account.all_balances()
          assert balances[:btc] == Decimal.new("1.8122774027894548")
          assert balances[:eth] == Decimal.new("0.000000000000200000000")
        end
      end

      test "#{adapter_id} adapter returns an error on network request time out" do
        use_cassette "exchange_adapters/shared/account/#{@adapter_id}/all_balances_error_timeout" do
          assert {:error, reason} = @adapter_id |> my_adapter |> Account.all_balances()
          assert reason == %TimeoutError{reason: "network request timed out"}
        end
      end
    end)
  end

  describe "#buy_limit" do
    test "returns an ok tuple when an order is successfully created" do
      assert {:ok, order_response} =
               Account.buy_limit(:test_account_a, :btcusd_success, 10.1, 2.2)

      assert order_response.id == "f9df7435-34d5-4861-8ddc-80f0fd2c83d7"
      assert order_response.status == :pending
      assert %DateTime{} = order_response.created_at
    end

    test "can take an order struct" do
      order = %Order{
        client_id: UUID.uuid4(),
        account_id: :test_account_a,
        symbol: :btcusd_success,
        side: Order.buy(),
        type: Order.limit(),
        price: 10.1,
        size: 2.2,
        status: OrderStatus.enqueued(),
        enqueued_at: Timex.now()
      }

      assert {:ok, order_response} = Account.buy_limit(order)
      assert order_response.id == "f9df7435-34d5-4861-8ddc-80f0fd2c83d7"
      assert order_response.status == :pending
      assert %DateTime{} = order_response.created_at
    end

    test "returns an error tuple when it is not the correct side or type" do
      buy_market_order = %Order{
        client_id: UUID.uuid4(),
        account_id: :test_account_a,
        symbol: :btcusd_success,
        side: Order.buy(),
        type: :market,
        price: 10.1,
        size: 2.2,
        status: OrderStatus.enqueued(),
        enqueued_at: Timex.now()
      }

      sell_limit_order = %Order{
        client_id: UUID.uuid4(),
        account_id: :test_account_a,
        symbol: :btcusd_success,
        side: Order.sell(),
        type: Order.limit(),
        price: 10.1,
        size: 2.2,
        status: OrderStatus.enqueued(),
        enqueued_at: Timex.now()
      }

      assert {:error, %OrderResponses.InvalidOrderType{}} = Account.buy_limit(buy_market_order)
      assert {:error, %OrderResponses.InvalidOrderType{}} = Account.buy_limit(sell_limit_order)
    end

    test "returns an error tuple when an order fails" do
      assert Account.buy_limit(:test_account_a, :btcusd_insufficient_funds, 10.1, 2.1) == {
               :error,
               %OrderResponses.InsufficientFunds{}
             }
    end
  end

  describe "#sell_limit" do
    test "returns an ok tuple when an order is successfully created" do
      assert {:ok, order_response} =
               Account.sell_limit(:test_account_a, :btcusd_success, 10.1, 2.2)

      assert order_response.id == "41541912-ebc1-4173-afa5-4334ccf7a1a8"
      assert order_response.status == :pending
      assert %DateTime{} = order_response.created_at
    end

    test "can take an order struct" do
      order = %Order{
        client_id: UUID.uuid4(),
        account_id: :test_account_a,
        symbol: :btcusd_success,
        side: Order.sell(),
        type: Order.limit(),
        price: 10.1,
        size: 2.2,
        status: OrderStatus.enqueued(),
        enqueued_at: Timex.now()
      }

      assert {:ok, order_response} = Account.sell_limit(order)
      assert order_response.id == "41541912-ebc1-4173-afa5-4334ccf7a1a8"
      assert order_response.status == :pending
      assert %DateTime{} = order_response.created_at
    end

    test "returns an error tuple when it is not the correct side or type" do
      sell_market_order = %Order{
        client_id: UUID.uuid4(),
        account_id: :test_account_a,
        symbol: :btcusd_success,
        side: Order.sell(),
        type: :market,
        price: 10.1,
        size: 2.2,
        status: OrderStatus.enqueued(),
        enqueued_at: Timex.now()
      }

      buy_limit_order = %Order{
        client_id: UUID.uuid4(),
        account_id: :test_account_a,
        symbol: :btcusd_success,
        side: Order.buy(),
        type: Order.limit(),
        price: 10.1,
        size: 2.2,
        status: OrderStatus.enqueued(),
        enqueued_at: Timex.now()
      }

      assert {:error, %OrderResponses.InvalidOrderType{}} = Account.sell_limit(sell_market_order)
      assert {:error, %OrderResponses.InvalidOrderType{}} = Account.sell_limit(buy_limit_order)
    end

    test "returns an {:error, reason} tuple when an order fails" do
      assert Account.sell_limit(:test_account_a, :btcusd_insufficient_funds, 10.1, 2.1) == {
               :error,
               %OrderResponses.InsufficientFunds{}
             }
    end
  end

  describe "#order_status" do
    test "returns an {:ok, status} tuple when it finds the order on the given account" do
      assert Account.order_status(:test_account_a, "f9df7435-34d5-4861-8ddc-80f0fd2c83d7") ==
               {:ok, :open}
    end

    test "return an {:error, reason} tuple when the order doesn't exist" do
      assert Account.order_status(:test_account_a, "invalid-order-id") ==
               {:error, "Invalid order id"}
    end
  end

  describe "#cancel_order" do
    test "cancels a previous order" do
      assert Account.cancel_order(:test_account_a, "f9df7435-34d5-4861-8ddc-80f0fd2c83d7") ==
               {:ok, "f9df7435-34d5-4861-8ddc-80f0fd2c83d7"}
    end

    test "displays error messages" do
      assert Account.cancel_order(:test_account_a, "invalid-order-id") ==
               {:error, "Invalid order id"}
    end
  end
end
