defmodule Tai.Exchanges.Boot.FeesTest do
  use ExUnit.Case, async: false
  doctest Tai.Exchanges.Boot.Fees

  defmodule MyAdapter do
    def maker_taker_fees(_venue_id, _account_id, _credentials) do
      {:ok, {Decimal.new("0.1"), Decimal.new("0.2")}}
    end
  end

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  @venue_id :venue_a
  @account_id :account_a
  @products [
    struct(Tai.Exchanges.Product, %{
      exchange_id: @venue_id,
      symbol: :btc_usd,
      maker_fee: Decimal.new("0.001"),
      taker_fee: Decimal.new("0.002")
    }),
    struct(Tai.Exchanges.Product, %{
      exchange_id: @venue_id,
      symbol: :eth_usd
    })
  ]
  @config Tai.Config.parse(
            venues: %{
              venue_a: [
                adapter: MyAdapter,
                products: "btc_usd",
                accounts: %{} |> Map.put(@account_id, %{})
              ]
            }
          )

  describe ".hydrate" do
    test "uses the lowest fee between the product or schedule" do
      [adapter] = Tai.Exchanges.Exchange.parse_adapters(@config)

      Tai.Exchanges.Boot.Fees.hydrate(adapter, @products)

      assert {:ok, btc_usd_fee} =
               Tai.Exchanges.FeeStore.find_by(
                 exchange_id: @venue_id,
                 account_id: @account_id,
                 symbol: :btc_usd
               )

      assert btc_usd_fee.maker == Decimal.new("0.001")
      assert btc_usd_fee.taker == Decimal.new("0.002")
    end

    test "uses the fee schedule when product doesn't have a maker/taker fee" do
      [adapter] = Tai.Exchanges.Exchange.parse_adapters(@config)

      Tai.Exchanges.Boot.Fees.hydrate(adapter, @products)

      assert {:ok, eth_usd_fee} =
               Tai.Exchanges.FeeStore.find_by(
                 exchange_id: @venue_id,
                 account_id: @account_id,
                 symbol: :eth_usd
               )

      assert eth_usd_fee.maker == Decimal.new("0.1")
      assert eth_usd_fee.taker == Decimal.new("0.2")
    end
  end
end
