defmodule Tai.Exchanges.AccountTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.Exchanges.Account

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
          assert {:ok, balances} =
                   @adapter_id |> my_adapter |> Tai.Exchanges.Account.all_balances()

          assert balances[:btc] == Decimal.new("1.8122774027894548")
          assert balances[:eth] == Decimal.new("0.000000000000200000000")
        end
      end

      test "#{adapter_id} adapter returns an error on network request time out" do
        use_cassette "exchange_adapters/shared/account/#{@adapter_id}/all_balances_error_timeout" do
          assert {:error, reason} =
                   @adapter_id |> my_adapter |> Tai.Exchanges.Account.all_balances()

          assert reason == %Tai.TimeoutError{reason: "network request timed out"}
        end
      end
    end)
  end

  @adapters [
    {Tai.ExchangeAdapters.Binance.Account, :binance},
    {Tai.ExchangeAdapters.Poloniex.Account, :poloniex}
  ]
  describe "#buy_limit" do
    @adapters
    |> Enum.map(fn {_, adapter_id} ->
      @adapter_id adapter_id

      test "#{adapter_id} adapter can create a fill or kill duration order" do
        use_cassette "exchange_adapters/shared/account/#{@adapter_id}/buy_limit_fill_or_kill_success" do
          assert {:ok, %Tai.Trading.OrderResponse{} = response} =
                   @adapter_id
                   |> my_adapter
                   |> Tai.Exchanges.Account.buy_limit(
                     :ltcbtc,
                     0.0165,
                     0.01,
                     Tai.Trading.TimeInForce.fill_or_kill()
                   )

          assert response.id != nil
          assert response.status == Tai.Trading.OrderStatus.expired()
          assert response.time_in_force == Tai.Trading.TimeInForce.fill_or_kill()
          assert Decimal.cmp(response.original_size, Decimal.new(0.01)) == :eq
          assert Decimal.cmp(response.executed_size, Decimal.new(0.01)) == :eq
        end
      end

      test "#{adapter_id} adapter returns an insufficient funds error tuple" do
        use_cassette "exchange_adapters/shared/account/#{@adapter_id}/buy_limit_fill_or_kill_error_insufficient_funds" do
          assert {:error, %Tai.Trading.InsufficientBalanceError{}} =
                   @adapter_id
                   |> my_adapter
                   |> Tai.Exchanges.Account.buy_limit(
                     :ltcbtc,
                     0.001,
                     10_000.01,
                     Tai.Trading.TimeInForce.fill_or_kill()
                   )
        end
      end

      test "#{adapter_id} adapter can create an immediate or cancel duration order" do
        use_cassette "exchange_adapters/shared/account/#{@adapter_id}/buy_limit_immediate_or_cancel_success" do
          assert {:ok, %Tai.Trading.OrderResponse{} = response} =
                   @adapter_id
                   |> my_adapter
                   |> Tai.Exchanges.Account.buy_limit(
                     :ltcbtc,
                     0.016,
                     0.02,
                     Tai.Trading.TimeInForce.immediate_or_cancel()
                   )

          assert response.id != nil
          assert response.status == Tai.Trading.OrderStatus.expired()
          assert response.time_in_force == Tai.Trading.TimeInForce.immediate_or_cancel()
          assert Decimal.cmp(response.original_size, Decimal.new(0.02)) == :eq
          assert Decimal.cmp(response.executed_size, Decimal.new(0.01)) == :eq
        end
      end
    end)
  end

  @adapters [
    {Tai.ExchangeAdapters.Binance.Account, :binance},
    {Tai.ExchangeAdapters.Poloniex.Account, :poloniex}
  ]
  describe "#sell_limit" do
    @adapters
    |> Enum.map(fn {_, adapter_id} ->
      @adapter_id adapter_id

      test "#{adapter_id} adapter can create a fill or kill duration order" do
        use_cassette "exchange_adapters/shared/account/#{@adapter_id}/sell_limit_fill_or_kill_success" do
          assert {:ok, %Tai.Trading.OrderResponse{} = response} =
                   @adapter_id
                   |> my_adapter
                   |> Tai.Exchanges.Account.sell_limit(
                     :ltcbtc,
                     0.16,
                     0.01,
                     Tai.Trading.TimeInForce.fill_or_kill()
                   )

          assert response.id != nil
          assert response.status == Tai.Trading.OrderStatus.expired()
          assert response.time_in_force == Tai.Trading.TimeInForce.fill_or_kill()
          assert Decimal.cmp(response.original_size, Decimal.new(0.01)) == :eq
          assert Decimal.cmp(response.executed_size, Decimal.new(0.01)) == :eq
        end
      end

      test "#{adapter_id} adapter can create an immediate or cancel duration order" do
        use_cassette "exchange_adapters/shared/account/#{@adapter_id}/sell_limit_immediate_or_cancel_success" do
          assert {:ok, %Tai.Trading.OrderResponse{} = response} =
                   @adapter_id
                   |> my_adapter
                   |> Tai.Exchanges.Account.sell_limit(
                     :ltcbtc,
                     0.16,
                     0.02,
                     Tai.Trading.TimeInForce.immediate_or_cancel()
                   )

          assert response.id != nil
          assert response.status == Tai.Trading.OrderStatus.expired()
          assert response.time_in_force == Tai.Trading.TimeInForce.immediate_or_cancel()
          assert Decimal.cmp(response.original_size, Decimal.new(0.02)) == :eq
          assert Decimal.cmp(response.executed_size, Decimal.new(0.01)) == :eq
        end
      end
    end)
  end
end
