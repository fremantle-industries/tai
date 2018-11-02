defmodule Tai.Exchanges.ExchangeTest do
  use ExUnit.Case, async: true
  doctest Tai.Exchanges.Exchange

  describe "#parse_adapters" do
    test "returns a list of adapters parsed from the config" do
      config =
        Tai.Config.parse(
          venues: %{
            exchange_a: [adapter: MyAdapterA],
            exchange_b: [adapter: MyAdapterB]
          },
          adapter_timeout: 100
        )

      assert Tai.Exchanges.Exchange.parse_adapters(config) == [
               %Tai.Exchanges.Adapter{
                 id: :exchange_a,
                 adapter: MyAdapterA,
                 timeout: 100,
                 products: "*",
                 accounts: %{}
               },
               %Tai.Exchanges.Adapter{
                 id: :exchange_b,
                 adapter: MyAdapterB,
                 timeout: 100,
                 products: "*",
                 accounts: %{}
               }
             ]
    end

    test "raises an KeyError when there is no adapter specified" do
      config = Tai.Config.parse(venues: %{invalid_exchange_a: []})

      assert_raise KeyError, "key :adapter not found in: []", fn ->
        Tai.Exchanges.Exchange.parse_adapters(config)
      end
    end

    test "can provide a timeout" do
      config =
        Tai.Config.parse(
          venues: %{
            exchange_a: [
              adapter: MyAdapterA,
              timeout: 10
            ]
          }
        )

      assert [
               %Tai.Exchanges.Adapter{
                 id: :exchange_a,
                 adapter: MyAdapterA,
                 timeout: 10
               }
             ] = Tai.Exchanges.Exchange.parse_adapters(config)
    end

    test "can provide a products filter" do
      config =
        Tai.Config.parse(
          venues: %{
            exchange_a: [
              adapter: MyAdapterA,
              products: "-btc_usd"
            ]
          }
        )

      assert [
               %Tai.Exchanges.Adapter{
                 id: :exchange_a,
                 adapter: MyAdapterA,
                 products: "-btc_usd"
               }
             ] = Tai.Exchanges.Exchange.parse_adapters(config)
    end

    test "can provide accounts" do
      config =
        Tai.Config.parse(
          venues: %{
            exchange_a: [
              adapter: MyAdapterA,
              accounts: %{main: %{}}
            ]
          }
        )

      assert [
               %Tai.Exchanges.Adapter{
                 id: :exchange_a,
                 adapter: MyAdapterA,
                 accounts: %{main: %{}}
               }
             ] = Tai.Exchanges.Exchange.parse_adapters(config)
    end
  end
end
