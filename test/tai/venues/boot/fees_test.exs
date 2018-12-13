defmodule Tai.Venues.Boot.FeesTest do
  use ExUnit.Case, async: false
  doctest Tai.Venues.Boot.Fees

  defmodule AdapterWithFeeSchedule do
    def maker_taker_fees(_, _, _), do: {:ok, {Decimal.new("0.1"), Decimal.new("0.2")}}
  end

  defmodule AdapterWithoutFeeSchedule do
    def maker_taker_fees(_, _, _), do: {:ok, nil}
  end

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  @venue_a :venue_a
  @venue_b :venue_b
  @account_a :account_a
  @account_b :account_b
  @btc_usd_product struct(Tai.Venues.Product, %{
                     exchange_id: @venue_a,
                     symbol: :btc_usd,
                     maker_fee: Decimal.new("0.001"),
                     taker_fee: Decimal.new("0.002")
                   })
  @eth_usd_product struct(Tai.Venues.Product, %{
                     exchange_id: @venue_a,
                     symbol: :eth_usd
                   })
  @ltc_usd_product struct(Tai.Venues.Product, %{
                     exchange_id: @venue_b,
                     symbol: :ltc_usd,
                     maker_fee: Decimal.new("0.003"),
                     taker_fee: Decimal.new("0.004")
                   })
  @config Tai.Config.parse(
            venues: %{
              venue_a: [
                adapter: AdapterWithFeeSchedule,
                accounts: %{} |> Map.put(@account_a, %{})
              ],
              venue_b: [
                adapter: AdapterWithoutFeeSchedule,
                accounts: %{} |> Map.put(@account_b, %{})
              ]
            }
          )

  describe ".hydrate" do
    test "uses the lowest fee between the product or schedule" do
      %{venue_a: adapter_a} = Tai.Venues.Config.parse_adapters(@config)

      Tai.Venues.Boot.Fees.hydrate(adapter_a, [@btc_usd_product, @eth_usd_product])

      assert {:ok, btc_usd_fee} =
               Tai.Venues.FeeStore.find_by(
                 exchange_id: @venue_a,
                 account_id: @account_a,
                 symbol: @btc_usd_product.symbol
               )

      assert btc_usd_fee.maker == Decimal.new("0.001")
      assert btc_usd_fee.taker == Decimal.new("0.002")
    end

    test "uses the fee schedule when product doesn't have a maker/taker fee" do
      %{venue_a: adapter_a} = Tai.Venues.Config.parse_adapters(@config)

      Tai.Venues.Boot.Fees.hydrate(adapter_a, [@btc_usd_product, @eth_usd_product])

      assert {:ok, eth_usd_fee} =
               Tai.Venues.FeeStore.find_by(
                 exchange_id: @venue_a,
                 account_id: @account_a,
                 symbol: @eth_usd_product.symbol
               )

      assert eth_usd_fee.maker == Decimal.new("0.1")
      assert eth_usd_fee.taker == Decimal.new("0.2")
    end

    test "uses the product fees when the venue doesn't have a fee schedule" do
      %{venue_b: adapter_b} = Tai.Venues.Config.parse_adapters(@config)

      Tai.Venues.Boot.Fees.hydrate(adapter_b, [@ltc_usd_product])

      assert {:ok, ltc_usd_fee} =
               Tai.Venues.FeeStore.find_by(
                 exchange_id: @venue_b,
                 account_id: @account_b,
                 symbol: :ltc_usd
               )

      assert ltc_usd_fee.maker == Decimal.new("0.003")
      assert ltc_usd_fee.taker == Decimal.new("0.004")
    end
  end
end
