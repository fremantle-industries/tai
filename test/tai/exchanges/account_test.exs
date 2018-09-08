defmodule Tai.Exchanges.AccountTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.Exchanges.Account

  # Test adapter would need to make HTTP requests for the shared test cases to 
  # work. This may be a good reason to use EchoBoy instead of matching on 
  # special symbols
  @binance_adapter {Tai.ExchangeAdapters.Binance.Account, :binance, :main, %{}}
  @gdax_adapter {Tai.ExchangeAdapters.Gdax.Account, :gdax, :main, %{}}
  @poloniex_adapter {Tai.ExchangeAdapters.Poloniex.Account, :poloniex, :main, %{}}
  @adapters [@binance_adapter, @gdax_adapter, @poloniex_adapter]

  setup_all do
    HTTPoison.start()

    @adapters
    |> Enum.map(fn {adapter, exchange_id, account_id, credentials} ->
      {adapter, [exchange_id: exchange_id, account_id: account_id, credentials: credentials]}
    end)
    |> Enum.map(&start_supervised!/1)

    :ok
  end

  describe "#all_balances" do
    @adapters
    |> Enum.map(fn {_, exchange_id, account_id, _credentials} ->
      @exchange_id exchange_id
      @account_id account_id

      test "#{exchange_id} adapter returns a map of assets" do
        use_cassette "exchange_adapters/shared/account/#{@exchange_id}/all_balances_success" do
          assert {:ok, balances} = Tai.Exchanges.Account.all_balances(@exchange_id, @account_id)

          assert Decimal.cmp(balances[:btc].free, Decimal.new("0.00020000")) == :eq
          assert Decimal.cmp(balances[:btc].locked, Decimal.new("1.80000000")) == :eq

          assert Decimal.cmp(balances[:eth].free, Decimal.new("0.20000000")) == :eq
          assert Decimal.cmp(balances[:eth].locked, Decimal.new("1.10000000")) == :eq
        end
      end

      test "#{exchange_id} adapter returns an error on network request time out" do
        use_cassette "exchange_adapters/shared/account/#{@exchange_id}/all_balances_error_timeout" do
          assert {:error, reason} = Tai.Exchanges.Account.all_balances(@exchange_id, @account_id)

          assert reason == %Tai.TimeoutError{reason: "network request timed out"}
        end
      end
    end)
  end

  @adapters [@binance_adapter, @poloniex_adapter]
  describe "#buy_limit" do
    @adapters
    |> Enum.map(fn {_, exchange_id, account_id, _credentials} ->
      @exchange_id exchange_id
      @account_id account_id

      test "#{exchange_id} adapter can create a fill or kill duration order" do
        use_cassette "exchange_adapters/shared/account/#{@exchange_id}/buy_limit_fill_or_kill_success" do
          assert {:ok, %Tai.Trading.OrderResponse{} = response} =
                   Tai.Exchanges.Account.buy_limit(
                     @exchange_id,
                     @account_id,
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

      test "#{exchange_id} adapter returns an insufficient funds error tuple" do
        use_cassette "exchange_adapters/shared/account/#{@exchange_id}/buy_limit_fill_or_kill_error_insufficient_funds" do
          assert {:error, %Tai.Trading.InsufficientBalanceError{}} =
                   Tai.Exchanges.Account.buy_limit(
                     @exchange_id,
                     @account_id,
                     :ltcbtc,
                     0.001,
                     10_000.01,
                     Tai.Trading.TimeInForce.fill_or_kill()
                   )
        end
      end

      test "#{exchange_id} adapter can create an immediate or cancel duration order" do
        use_cassette "exchange_adapters/shared/account/#{@exchange_id}/buy_limit_immediate_or_cancel_success" do
          assert {:ok, %Tai.Trading.OrderResponse{} = response} =
                   Tai.Exchanges.Account.buy_limit(
                     @exchange_id,
                     @account_id,
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

  @adapters [@binance_adapter, @poloniex_adapter]
  describe "#sell_limit" do
    @adapters
    |> Enum.map(fn {_, exchange_id, account_id, _credentials} ->
      @exchange_id exchange_id
      @account_id account_id

      test "#{exchange_id} adapter can create a fill or kill duration order" do
        use_cassette "exchange_adapters/shared/account/#{@exchange_id}/sell_limit_fill_or_kill_success" do
          assert {:ok, %Tai.Trading.OrderResponse{} = response} =
                   Tai.Exchanges.Account.sell_limit(
                     @exchange_id,
                     @account_id,
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

      test "#{exchange_id} adapter can create an immediate or cancel duration order" do
        use_cassette "exchange_adapters/shared/account/#{@exchange_id}/sell_limit_immediate_or_cancel_success" do
          assert {:ok, %Tai.Trading.OrderResponse{} = response} =
                   Tai.Exchanges.Account.sell_limit(
                     @exchange_id,
                     @account_id,
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
