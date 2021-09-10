defmodule Tai.IEx.Commands.FleetsTest do
  use Tai.TestSupport.DataCase, async: false
  import ExUnit.CaptureIO

  test "shows all advisors in all fleets ordered fleet id, advisor id by default" do
    mock_fleet_config(%{id: :log_spread, quotes: "venue_a.btc_usd"})
    mock_fleet_config(%{id: :trade_spread, quotes: "venue_b.eth_usd"})

    assert capture_io(&Tai.IEx.fleets/0) == """
           +--------------+---------------+-----------------+---------------------------------------------+----------------------------+
           |           ID | Start on Boot |          Quotes |                                     Factory |                    Advisor |
           +--------------+---------------+-----------------+---------------------------------------------+----------------------------+
           |   log_spread |         false | venue_a.btc_usd | Elixir.Tai.Advisors.Factories.OnePerProduct | Elixir.Support.NoopAdvisor |
           | trade_spread |         false | venue_b.eth_usd | Elixir.Tai.Advisors.Factories.OnePerProduct | Elixir.Support.NoopAdvisor |
           +--------------+---------------+-----------------+---------------------------------------------+----------------------------+\n
           """
  end

  test "shows an empty table when there are no fleets" do
    assert capture_io(&Tai.IEx.fleets/0) == """
           +----+---------------+--------+---------+---------+
           | ID | Start on Boot | Quotes | Factory | Advisor |
           +----+---------------+--------+---------+---------+
           |  - |             - |      - |       - |       - |
           +----+---------------+--------+---------+---------+\n
           """
  end

  test "can filter by struct attributes" do
    mock_fleet_config(%{id: :log_spread, quotes: "venue_a.btc_usd"})
    mock_fleet_config(%{id: :trade_spread, quotes: "venue_b.eth_usd"})

    assert capture_io(fn -> Tai.IEx.fleets(where: [id: :log_spread]) end) == """
           +------------+---------------+-----------------+---------------------------------------------+----------------------------+
           |         ID | Start on Boot |          Quotes |                                     Factory |                    Advisor |
           +------------+---------------+-----------------+---------------------------------------------+----------------------------+
           | log_spread |         false | venue_a.btc_usd | Elixir.Tai.Advisors.Factories.OnePerProduct | Elixir.Support.NoopAdvisor |
           +------------+---------------+-----------------+---------------------------------------------+----------------------------+\n
           """
  end

  test "can order ascending by struct attributes" do
    mock_fleet_config(%{id: :log_spread_b, quotes: "venue_b.eth_usd"})
    mock_fleet_config(%{id: :log_spread_a, quotes: "venue_a.btc_usd"})

    assert capture_io(fn -> Tai.IEx.fleets(order: [:id]) end) == """
           +--------------+---------------+-----------------+---------------------------------------------+----------------------------+
           |           ID | Start on Boot |          Quotes |                                     Factory |                    Advisor |
           +--------------+---------------+-----------------+---------------------------------------------+----------------------------+
           | log_spread_a |         false | venue_a.btc_usd | Elixir.Tai.Advisors.Factories.OnePerProduct | Elixir.Support.NoopAdvisor |
           | log_spread_b |         false | venue_b.eth_usd | Elixir.Tai.Advisors.Factories.OnePerProduct | Elixir.Support.NoopAdvisor |
           +--------------+---------------+-----------------+---------------------------------------------+----------------------------+\n
           """
  end
end
