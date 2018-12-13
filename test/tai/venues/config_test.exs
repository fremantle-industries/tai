defmodule Tai.Venues.ConfigTest do
  use ExUnit.Case, async: true
  doctest Tai.Venues.Config

  describe ".parse_adapters" do
    test "returns a map of adapters parsed from the config" do
      config =
        Tai.Config.parse(
          venues: %{
            venue_a: [adapter: MyAdapterA],
            venue_b: [adapter: MyAdapterB]
          },
          adapter_timeout: 100
        )

      assert Tai.Venues.Config.parse_adapters(config) == %{
               venue_a: %Tai.Venues.Adapter{
                 id: :venue_a,
                 adapter: MyAdapterA,
                 timeout: 100,
                 products: "*",
                 accounts: %{}
               },
               venue_b: %Tai.Venues.Adapter{
                 id: :venue_b,
                 adapter: MyAdapterB,
                 timeout: 100,
                 products: "*",
                 accounts: %{}
               }
             }
    end

    test "raises an KeyError when there is no adapter specified" do
      config = Tai.Config.parse(venues: %{invalid_exchange_a: []})

      assert_raise KeyError, "key :adapter not found in: []", fn ->
        Tai.Venues.Config.parse_adapters(config)
      end
    end

    test "can provide a timeout" do
      config =
        Tai.Config.parse(
          venues: %{
            venue_a: [
              adapter: MyAdapterA,
              timeout: 10
            ]
          }
        )

      assert %{
               venue_a: %Tai.Venues.Adapter{
                 id: :venue_a,
                 adapter: MyAdapterA,
                 timeout: 10
               }
             } = Tai.Venues.Config.parse_adapters(config)
    end

    test "can provide a products filter" do
      config =
        Tai.Config.parse(
          venues: %{
            venue_a: [
              adapter: MyAdapterA,
              products: "-btc_usd"
            ]
          }
        )

      assert %{
               venue_a: %Tai.Venues.Adapter{
                 id: :venue_a,
                 adapter: MyAdapterA,
                 products: "-btc_usd"
               }
             } = Tai.Venues.Config.parse_adapters(config)
    end

    test "can provide accounts" do
      config =
        Tai.Config.parse(
          venues: %{
            venue_a: [
              adapter: MyAdapterA,
              accounts: %{main: %{}}
            ]
          }
        )

      assert %{
               venue_a: %Tai.Venues.Adapter{
                 id: :venue_a,
                 adapter: MyAdapterA,
                 accounts: %{main: %{}}
               }
             } = Tai.Venues.Config.parse_adapters(config)
    end
  end
end
