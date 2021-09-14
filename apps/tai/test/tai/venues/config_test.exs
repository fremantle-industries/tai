defmodule Tai.Venues.ConfigTest do
  use ExUnit.Case, async: true
  doctest Tai.Venues.Config

  describe ".parse" do
    test "returns a map of adapters parsed from the config" do
      config =
        Tai.Config.parse(
          venues: %{
            venue_a: [start_on_boot: true, adapter: MyAdapterA],
            venue_b: [start_on_boot: true, adapter: MyAdapterB],
            venue_c: [start_on_boot: false, adapter: MyAdapterC]
          },
          adapter_timeout: 100
        )

      venues = Tai.Venues.Config.parse(config)
      assert Enum.count(venues) == 3

      assert Enum.at(venues, 0).id == :venue_a
      assert Enum.at(venues, 0).adapter == MyAdapterA
      assert Enum.at(venues, 0).start_on_boot == true
      assert Enum.at(venues, 1).id == :venue_b
      assert Enum.at(venues, 1).adapter == MyAdapterB
      assert Enum.at(venues, 1).start_on_boot == true
      assert Enum.at(venues, 2).id == :venue_c
      assert Enum.at(venues, 2).adapter == MyAdapterC
      assert Enum.at(venues, 2).start_on_boot == false
    end

    test "assigns all products when not provided" do
      config = Tai.Config.parse(venues: %{venue_a: [enabled: true, adapter: MyAdapterA]})

      venues = Tai.Venues.Config.parse(config)
      assert Enum.at(venues, 0).products == "*"
    end

    test "assigns all market streams when not provided" do
      config = Tai.Config.parse(venues: %{venue_a: [enabled: true, adapter: MyAdapterA]})

      venues = Tai.Venues.Config.parse(config)
      assert Enum.at(venues, 0).market_streams == "*"
    end

    test "assigns all accounts when not provided" do
      config = Tai.Config.parse(venues: %{venue_a: [enabled: true, adapter: MyAdapterA]})

      venues = Tai.Venues.Config.parse(config)
      assert Enum.at(venues, 0).accounts == "*"
    end

    test "assigns empty channels when not provided" do
      config = Tai.Config.parse(venues: %{venue_a: [enabled: true, adapter: MyAdapterA]})

      venues = Tai.Venues.Config.parse(config)
      assert Enum.at(venues, 0).channels == []
    end

    test "assigns a quote depth of 1 when not provided" do
      config = Tai.Config.parse(venues: %{venue_a: [enabled: true, adapter: MyAdapterA]})

      venues = Tai.Venues.Config.parse(config)
      assert Enum.at(venues, 0).quote_depth == 1
    end

    test "assigns a stream heartbeat interval when not provided" do
      config = Tai.Config.parse(venues: %{venue_a: [enabled: true, adapter: MyAdapterA]})

      venues = Tai.Venues.Config.parse(config)
      assert Enum.at(venues, 0).stream_heartbeat_interval == 5000
    end

    test "assigns a stream heartbeat timeout when not provided" do
      config = Tai.Config.parse(venues: %{venue_a: [enabled: true, adapter: MyAdapterA]})

      venues = Tai.Venues.Config.parse(config)
      assert Enum.at(venues, 0).stream_heartbeat_timeout == 3000
    end

    test "can provide channels" do
      config =
        Tai.Config.parse(
          venues: %{
            venue_a: [enabled: true, adapter: MyAdapterA, channels: [:channel_a]]
          }
        )

      venues = Tai.Venues.Config.parse(config)
      assert Enum.at(venues, 0).channels == [:channel_a]
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

      venues = Tai.Venues.Config.parse(config)
      assert Enum.at(venues, 0).timeout == 10
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

      venues = Tai.Venues.Config.parse(config)
      assert Enum.at(venues, 0).products == "-btc_usd"
    end

    test "can provide an order book filter" do
      config =
        Tai.Config.parse(
          venues: %{
            venue_a: [
              enabled: true,
              adapter: MyAdapterA,
              market_streams: "-ltc_usd"
            ]
          }
        )

      venues = Tai.Venues.Config.parse(config)
      assert Enum.at(venues, 0).market_streams == "-ltc_usd"
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

      venues = Tai.Venues.Config.parse(config)
      assert Enum.at(venues, 0).accounts == "-btc"
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

      venues = Tai.Venues.Config.parse(config)
      assert Enum.at(venues, 0).credentials == %{main: %{}}
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

      venues = Tai.Venues.Config.parse(config)
      assert Enum.at(venues, 0).quote_depth == 5
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

      venues = Tai.Venues.Config.parse(config)
      assert Enum.at(venues, 0).broadcast_change_set
    end

    test "can provide a stream heartbeat interval" do
      config =
        Tai.Config.parse(
          venues: %{
            venue_a: [
              enabled: true,
              adapter: MyAdapterA,
              stream_heartbeat_interval: 10_000
            ]
          }
        )

      venues = Tai.Venues.Config.parse(config)
      assert Enum.at(venues, 0).stream_heartbeat_interval == 10_000
    end

    test "can provide a stream heartbeat timeout" do
      config =
        Tai.Config.parse(
          venues: %{
            venue_a: [
              enabled: true,
              adapter: MyAdapterA,
              stream_heartbeat_timeout: 7_000
            ]
          }
        )

      venues = Tai.Venues.Config.parse(config)
      assert Enum.at(venues, 0).stream_heartbeat_timeout == 7_000
    end

    test "raises a KeyError when there is no adapter specified" do
      config = Tai.Config.parse(venues: %{invalid_exchange_a: [start_on_boot: true]})

      assert_raise KeyError, "key :adapter not found in: [start_on_boot: true]", fn ->
        Tai.Venues.Config.parse(config)
      end
    end
  end
end
