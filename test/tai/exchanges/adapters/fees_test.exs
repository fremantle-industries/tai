defmodule Tai.Exchanges.Adapters.FeesTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @exchanges [
    %Tai.Exchanges.Config{
      id: :binance,
      supervisor: Tai.ExchangeAdapters.Binance.Supervisor,
      accounts: %{main: %{}}
    },
    # TODO:
    # exvcr can't distinguish between the account balance and fee info requests.
    # It matches on the URL and Poloniex uses the same URL with different body
    # parameters.
    #
    # A potential solution is to add regex body matching to exvcr...
    #
    # %Tai.Exchanges.Config{
    #   id: :poloniex,
    #   supervisor: Tai.ExchangeAdapters.Poloniex.Supervisor,
    #   accounts: %{main: %{}}
    # },
    %Tai.Exchanges.Config{
      id: :gdax,
      supervisor: Tai.ExchangeAdapters.Gdax.Supervisor,
      accounts: %{
        main: %{
          api_url: "https://api-public.sandbox.pro.coinbase.com",
          api_key: System.get_env("GDAX_API_KEY"),
          api_secret: System.get_env("GDAX_API_SECRET"),
          api_passphrase: System.get_env("GDAX_API_PASSPHRASE")
        }
      }
    }
  ]

  setup_all do
    on_exit(fn ->
      Tai.Exchanges.Products.clear()
      Tai.Exchanges.Fees.clear()
    end)

    HTTPoison.start()
    Process.register(self(), :test)
    :ok
  end

  @exchanges
  |> Enum.map(fn config ->
    @config config

    test "#{config.id} retrieves fee details for each exchange account" do
      exchange_id = @config.id
      account_id = @config.accounts |> Map.keys() |> List.first()
      symbol = :ltc_btc
      Tai.Boot.subscribe_fees(exchange_id, account_id)

      assert {:error, :not_found} =
               Tai.Exchanges.Fees.find_by(
                 exchange_id: exchange_id,
                 account_id: account_id,
                 symbol: symbol
               )

      use_cassette "exchange_adapters/shared/fees/#{exchange_id}/init_success" do
        start_supervised!({@config.supervisor, @config})

        assert_receive {:hydrated_fees, :ok, ^exchange_id, ^account_id}, 1_000
      end

      assert {:ok, %Tai.Exchanges.FeeInfo{} = fee} =
               Tai.Exchanges.Fees.find_by(
                 exchange_id: exchange_id,
                 account_id: account_id,
                 symbol: symbol
               )

      assert fee.exchange_id == exchange_id
      assert fee.account_id == account_id
      assert fee.symbol == symbol
      assert %Decimal{} = fee.maker
      assert fee.maker_type == Tai.Exchanges.FeeInfo.percent()
      assert %Decimal{} = fee.taker
      assert fee.taker_type == Tai.Exchanges.FeeInfo.percent()

      Tai.Boot.unsubscribe_fees(exchange_id, account_id)
    end
  end)
end
