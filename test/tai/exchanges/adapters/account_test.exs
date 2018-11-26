defmodule Tai.Exchanges.Adapters.AccountTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @gdax_credentials %{
    api_url: "https://api-public.sandbox.pro.coinbase.com",
    api_key: System.get_env("GDAX_API_KEY"),
    api_secret: System.get_env("GDAX_API_SECRET"),
    api_passphrase: System.get_env("GDAX_API_PASSPHRASE")
  }
  @gdax_adapter {Tai.ExchangeAdapters.Gdax.Account, :gdax, :main, @gdax_credentials}

  @binance_adapter {Tai.ExchangeAdapters.Binance.Account, :binance, :main, %{}}
  @poloniex_adapter {Tai.ExchangeAdapters.Poloniex.Account, :poloniex, :main, %{}}

  # Test adapter would need to make HTTP requests for the shared test cases to 
  # work. This may be a good reason to use EchoBoy instead of matching on 
  # special symbols
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

  @adapters [@binance_adapter, @poloniex_adapter]
  describe ".buy_limit" do
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
  describe ".sell_limit" do
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
