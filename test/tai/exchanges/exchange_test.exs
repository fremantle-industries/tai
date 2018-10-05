defmodule Tai.Exchanges.ExchangeTest do
  use ExUnit.Case, async: true
  doctest Tai.Exchanges.Exchange

  describe "#parse_configs!" do
    test "returns a list of adapters parsed from the config" do
      configs = %{
        exchange_a: [adapter: MyAdapterA],
        exchange_b: [adapter: MyAdapterB]
      }

      assert Tai.Exchanges.Exchange.parse_configs(configs) == [
               %Tai.Exchanges.Adapter{
                 id: :exchange_a,
                 adapter: MyAdapterA,
                 products: "*",
                 accounts: %{}
               },
               %Tai.Exchanges.Adapter{
                 id: :exchange_b,
                 adapter: MyAdapterB,
                 products: "*",
                 accounts: %{}
               }
             ]
    end

    test "raises an KeyError when there is no adapter specified" do
      configs = %{invalid_exchange_a: []}

      assert_raise KeyError, "key :adapter not found in: []", fn ->
        Tai.Exchanges.Exchange.parse_configs(configs)
      end
    end

    test "can provide a products filter" do
      configs = %{
        exchange_a: [
          adapter: MyAdapterA,
          products: "-btc_usd"
        ]
      }

      assert Tai.Exchanges.Exchange.parse_configs(configs) == [
               %Tai.Exchanges.Adapter{
                 id: :exchange_a,
                 adapter: MyAdapterA,
                 products: "-btc_usd",
                 accounts: %{}
               }
             ]
    end

    test "can provide accounts" do
      configs = %{
        exchange_a: [
          adapter: MyAdapterA,
          accounts: %{main: %{}}
        ]
      }

      assert Tai.Exchanges.Exchange.parse_configs(configs) == [
               %Tai.Exchanges.Adapter{
                 id: :exchange_a,
                 adapter: MyAdapterA,
                 products: "*",
                 accounts: %{main: %{}}
               }
             ]
    end
  end
end
