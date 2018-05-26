defmodule Tai.Exchanges.AccountTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.Exchanges.Account

  alias Tai.TimeoutError
  alias Tai.Exchanges.Account
  alias Tai.Trading.{OrderResponse, OrderStatus}
  alias Tai.Trading.OrderDurations.FillOrKill

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

  @adapters [
    {Tai.ExchangeAdapters.Binance.Account, :binance},
    {Tai.ExchangeAdapters.Poloniex.Account, :poloniex}
  ]
  describe "#buy_limit" do
    @adapters
    |> Enum.map(fn {_, adapter_id} ->
      @adapter_id adapter_id
      test "#{adapter_id} can create a fill or kill duration order" do
        use_cassette "exchange_adapters/shared/account/#{@adapter_id}/buy_limit_fill_or_kill_success" do
          assert {:ok, %OrderResponse{} = response} =
                   @adapter_id
                   |> my_adapter
                   |> Account.buy_limit(:ltcbtc, 0.0165, 0.01, %FillOrKill{})

          assert response.id != nil
          assert response.status == OrderStatus.expired()
          assert response.time_in_force == %FillOrKill{}
          assert Decimal.cmp(response.original_size, Decimal.new(0.01)) == :eq
          assert Decimal.cmp(response.executed_size, Decimal.new(0.01)) == :eq
        end
      end
    end)
  end
end
