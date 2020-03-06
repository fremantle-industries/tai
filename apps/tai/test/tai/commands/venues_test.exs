defmodule Tai.Commands.VenuesTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  @test_store_id __MODULE__

  setup do
    start_supervised!(Tai.Venues.StreamsSupervisor)
    start_supervised!({Tai.Venues.VenueStore, id: @test_store_id})
    :ok
  end

  test "shows a table of all venues" do
    {:ok, _} =
      struct(
        Tai.Venue,
        id: :venue_a,
        credentials: %{primary: %{}, secondary: %{}},
        channels: [:trades, :liquidations],
        quote_depth: 2,
        timeout: 1_000,
        start_on_boot: false
      )
      |> Tai.Venues.VenueStore.put(@test_store_id)

    {:ok, _} =
      struct(
        Tai.Venue,
        id: :venue_b,
        credentials: %{main: %{}},
        channels: [:trades],
        quote_depth: 1,
        timeout: 1_000,
        start_on_boot: false
      )
      |> Tai.Venues.VenueStore.put(@test_store_id)

    assert capture_io(fn -> Tai.CommandsHelper.venues(store_id: @test_store_id) end) == """
           +---------+--------------------+---------+----------------------+-------------+---------+---------------+
           |      ID |        Credentials |  Status |             Channels | Quote Depth | Timeout | Start On Boot |
           +---------+--------------------+---------+----------------------+-------------+---------+---------------+
           | venue_a | primary, secondary | stopped | trades, liquidations |           2 |    1000 |         false |
           | venue_b |               main | stopped |               trades |           1 |    1000 |         false |
           +---------+--------------------+---------+----------------------+-------------+---------+---------------+\n
           """
  end

  test "can filter by struct attributes" do
    {:ok, _} =
      struct(
        Tai.Venue,
        id: :venue_a,
        credentials: %{primary: %{}, secondary: %{}},
        channels: [:trades, :liquidations],
        quote_depth: 2,
        timeout: 1_000,
        start_on_boot: false
      )
      |> Tai.Venues.VenueStore.put(@test_store_id)

    {:ok, _} =
      struct(
        Tai.Venue,
        id: :venue_b,
        credentials: %{main: %{}},
        channels: [:trades],
        quote_depth: 1,
        timeout: 1_000,
        start_on_boot: false
      )
      |> Tai.Venues.VenueStore.put(@test_store_id)

    assert capture_io(fn ->
             Tai.CommandsHelper.venues(
               where: [id: :venue_a],
               store_id: @test_store_id
             )
           end) == """
           +---------+--------------------+---------+----------------------+-------------+---------+---------------+
           |      ID |        Credentials |  Status |             Channels | Quote Depth | Timeout | Start On Boot |
           +---------+--------------------+---------+----------------------+-------------+---------+---------------+
           | venue_a | primary, secondary | stopped | trades, liquidations |           2 |    1000 |         false |
           +---------+--------------------+---------+----------------------+-------------+---------+---------------+\n
           """
  end

  test "can order ascending by struct attributes" do
    {:ok, _} =
      struct(
        Tai.Venue,
        id: :venue_a,
        credentials: %{primary: %{}, secondary: %{}},
        channels: [:trades, :liquidations],
        quote_depth: 2,
        timeout: 1_000,
        start_on_boot: false
      )
      |> Tai.Venues.VenueStore.put(@test_store_id)

    {:ok, _} =
      struct(
        Tai.Venue,
        id: :venue_b,
        credentials: %{main: %{}},
        channels: [:trades],
        quote_depth: 1,
        timeout: 1_000,
        start_on_boot: false
      )
      |> Tai.Venues.VenueStore.put(@test_store_id)

    assert capture_io(fn ->
             Tai.CommandsHelper.venues(
               order: [:quote_depth],
               store_id: @test_store_id
             )
           end) == """
           +---------+--------------------+---------+----------------------+-------------+---------+---------------+
           |      ID |        Credentials |  Status |             Channels | Quote Depth | Timeout | Start On Boot |
           +---------+--------------------+---------+----------------------+-------------+---------+---------------+
           | venue_b |               main | stopped |               trades |           1 |    1000 |         false |
           | venue_a | primary, secondary | stopped | trades, liquidations |           2 |    1000 |         false |
           +---------+--------------------+---------+----------------------+-------------+---------+---------------+\n
           """
  end

  test "shows an empty table when there are no venues" do
    assert capture_io(fn -> Tai.CommandsHelper.venues(store_id: @test_store_id) end) == """
           +----+-------------+--------+----------+-------------+---------+---------------+
           | ID | Credentials | Status | Channels | Quote Depth | Timeout | Start On Boot |
           +----+-------------+--------+----------+-------------+---------+---------------+
           |  - |           - |      - |        - |           - |       - |             - |
           +----+-------------+--------+----------+-------------+---------+---------------+\n
           """
  end
end
