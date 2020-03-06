defmodule Tai.Venues.InstanceTest do
  use ExUnit.Case, async: false

  defmodule VenueAdapter do
    use Support.StartVenueAdapter
  end

  defmodule MockStart do
    use Agent

    def start_link(venue) do
      name = Tai.Venues.Start.to_name(venue.id)
      Agent.start_link(fn -> %{} end, name: name)
    end
  end

  @test_store_id __MODULE__
  @venue struct(Tai.Venue, id: :venue_a, adapter: VenueAdapter)

  setup do
    start_supervised!(Tai.Venues.StreamsSupervisor)
    start_supervised!(Tai.Venues.Supervisor)
    start_supervised!({Tai.Venues.VenueStore, id: @test_store_id})
    :ok
  end

  describe ".find/1" do
    test "returns the pid of the start venue process" do
      start_pid = start_supervised!({MockStart, @venue})

      assert {:ok, pid} = Tai.Venues.Instance.find(@venue)
      assert pid == start_pid
    end

    test "returns an error when the process is stopped" do
      assert Tai.Venues.Instance.find(@venue) == {:error, :not_found}
    end
  end

  describe ".find_stream/1" do
    test "returns the pid of the stream" do
      {:ok, stream_pid} = Tai.Venues.StreamsSupervisor.start(@venue, [])

      assert {:ok, pid} = Tai.Venues.Instance.find_stream(@venue)
      assert pid == stream_pid
    end

    test "returns an error when the stream is stopped" do
      assert Tai.Venues.Instance.find_stream(@venue) == {:error, :not_found}
    end
  end

  describe ".stop/1" do
    test "stops the stream and start venue processes" do
      {:ok, start_pid} = Tai.Venues.Supervisor.start(@venue)
      {:ok, stream_pid} = Tai.Venues.StreamsSupervisor.start(@venue, [])

      assert Tai.Venues.Instance.stop(@venue) == :ok
      assert Process.alive?(start_pid) == false
      assert Process.alive?(stream_pid) == false
    end

    test "returns an error when the stream or start venue process can't be found" do
      assert Tai.Venues.Instance.stop(@venue) == {:error, :already_stopped}
    end
  end
end
