defmodule Tai.Venues.ConfigTest do
  use ExUnit.Case, async: true
  doctest Tai.Venues.Config

  describe ".parse" do
    test "returns a map of adapters parsed from the config" do
      config =
        Tai.Config.parse(
          venues: %{
            venue_a: [enabled: true, adapter: MyAdapterA],
            venue_b: [enabled: true, adapter: MyAdapterB],
            venue_c: [enabled: false, adapter: MyAdapterC]
          },
          adapter_timeout: 100
        )

      assert %{
               venue_a: venue_a,
               venue_b: venue_b
             } = Tai.Venues.Config.parse(config)

      assert venue_a.id == :venue_a
      assert venue_a.adapter == MyAdapterA
      assert venue_b.id == :venue_b
      assert venue_b.adapter == MyAdapterB
    end

    test "assigns all products when not provided" do
      config = Tai.Config.parse(venues: %{venue_a: [enabled: true, adapter: MyAdapterA]})

      assert %{venue_a: venue} = Tai.Venues.Config.parse(config)
      assert venue.products == "*"
    end

    test "assigns all accounts when not provided" do
      config = Tai.Config.parse(venues: %{venue_a: [enabled: true, adapter: MyAdapterA]})

      assert %{venue_a: venue} = Tai.Venues.Config.parse(config)
      assert venue.accounts == "*"
    end

    test "assigns empty channels when not provided" do
      config = Tai.Config.parse(venues: %{venue_a: [enabled: true, adapter: MyAdapterA]})

      assert %{venue_a: venue} = Tai.Venues.Config.parse(config)
      assert venue.channels == []
    end

    test "assigns a quote depth of 1 when not provided" do
      config = Tai.Config.parse(venues: %{venue_a: [enabled: true, adapter: MyAdapterA]})

      assert %{venue_a: venue} = Tai.Venues.Config.parse(config)
      assert venue.quote_depth == 1
    end

    test "can provide channels" do
      config =
        Tai.Config.parse(
          venues: %{
            venue_a: [enabled: true, adapter: MyAdapterA, channels: [:channel_a]]
          }
        )

      assert %{venue_a: venue} = Tai.Venues.Config.parse(config)
      assert venue.channels == [:channel_a]
    end

    test "can provide a timeout" do
      config =
        Tai.Config.parse(
          venues: %{
            venue_a: [
              enabled: true,
              adapter: MyAdapterA,
              timeout: 10
            ]
          }
        )

      assert %{
               venue_a: %Tai.Venue{
                 id: :venue_a,
                 adapter: MyAdapterA,
                 timeout: 10
               }
             } = Tai.Venues.Config.parse(config)
    end

    test "can provide a products filter" do
      config =
        Tai.Config.parse(
          venues: %{
            venue_a: [
              enabled: true,
              adapter: MyAdapterA,
              products: "-btc_usd"
            ]
          }
        )

      assert %{
               venue_a: %Tai.Venue{
                 id: :venue_a,
                 adapter: MyAdapterA,
                 products: "-btc_usd"
               }
             } = Tai.Venues.Config.parse(config)
    end

    test "can provide an accounts filter" do
      config =
        Tai.Config.parse(
          venues: %{
            venue_a: [
              enabled: true,
              adapter: MyAdapterA,
              accounts: "-btc"
            ]
          }
        )

      assert %{
               venue_a: %Tai.Venue{
                 id: :venue_a,
                 adapter: MyAdapterA,
                 accounts: "-btc"
               }
             } = Tai.Venues.Config.parse(config)
    end

    test "can provide credentials" do
      config =
        Tai.Config.parse(
          venues: %{
            venue_a: [
              enabled: true,
              adapter: MyAdapterA,
              credentials: %{main: %{}}
            ]
          }
        )

      assert %{
               venue_a: %Tai.Venue{
                 id: :venue_a,
                 adapter: MyAdapterA,
                 credentials: %{main: %{}}
               }
             } = Tai.Venues.Config.parse(config)
    end

    test "can provide a quote depth" do
      config =
        Tai.Config.parse(
          venues: %{
            venue_a: [
              enabled: true,
              adapter: MyAdapterA,
              quote_depth: 5
            ]
          }
        )

      assert %{venue_a: venue} = Tai.Venues.Config.parse(config)
      assert venue.quote_depth == 5
    end

    test "can provide broadcast_change_set" do
      config =
        Tai.Config.parse(
          venues: %{
            venue_a: [
              enabled: true,
              adapter: MyAdapterA,
              broadcast_change_set: true
            ]
          }
        )

      assert %{venue_a: venue} = Tai.Venues.Config.parse(config)
      assert venue.broadcast_change_set
    end

    test "raises a KeyError when there is no adapter specified" do
      config = Tai.Config.parse(venues: %{invalid_exchange_a: [enabled: true]})

      assert_raise KeyError, "key :adapter not found in: [enabled: true]", fn ->
        Tai.Venues.Config.parse(config)
      end
    end
  end
end
