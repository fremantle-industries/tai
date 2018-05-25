defmodule Tai.Exchanges.AccountTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.Exchanges.Account

  alias Tai.TimeoutError
  alias Tai.Exchanges.Account

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
  end
end
