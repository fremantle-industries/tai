defmodule Tai.IEx.Commands.VenuesTest do
  use Tai.TestSupport.DataCase, async: false
  import ExUnit.CaptureIO

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
      |> Tai.Venues.VenueStore.put()

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
      |> Tai.Venues.VenueStore.put()

    assert capture_io(&Tai.IEx.venues/0) == """
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
      |> Tai.Venues.VenueStore.put()

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
      |> Tai.Venues.VenueStore.put()

    assert capture_io(fn -> Tai.IEx.venues(where: [id: :venue_a]) end) == """
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
      |> Tai.Venues.VenueStore.put()

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
      |> Tai.Venues.VenueStore.put()

    assert capture_io(fn -> Tai.IEx.venues(order: [:quote_depth]) end) == """
           +---------+--------------------+---------+----------------------+-------------+---------+---------------+
           |      ID |        Credentials |  Status |             Channels | Quote Depth | Timeout | Start On Boot |
           +---------+--------------------+---------+----------------------+-------------+---------+---------------+
           | venue_b |               main | stopped |               trades |           1 |    1000 |         false |
           | venue_a | primary, secondary | stopped | trades, liquidations |           2 |    1000 |         false |
           +---------+--------------------+---------+----------------------+-------------+---------+---------------+\n
           """
  end

  test "shows an empty table when there are no venues" do
    assert capture_io(&Tai.IEx.venues/0) == """
           +----+-------------+--------+----------+-------------+---------+---------------+
           | ID | Credentials | Status | Channels | Quote Depth | Timeout | Start On Boot |
           +----+-------------+--------+----------+-------------+---------+---------------+
           |  - |           - |      - |        - |           - |       - |             - |
           +----+-------------+--------+----------+-------------+---------+---------------+\n
           """
  end
end
