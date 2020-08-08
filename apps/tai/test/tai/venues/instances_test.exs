defmodule Tai.Venues.InstancesTest do
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

  @venue struct(Tai.Venue, id: :venue_a, adapter: VenueAdapter)
  @stream struct(Tai.Venues.Stream, venue: @venue)

  setup do
    start_supervised!(Tai.Venues.StreamsSupervisor)
    start_supervised!(Tai.Venues.Supervisor)
    :ok
  end

  describe ".find/1" do
    test "returns the pid of the start venue process" do
      start_pid = start_supervised!({MockStart, @venue})

      assert {:ok, pid} = Tai.Venues.Instances.find(@venue)
      assert pid == start_pid
    end

    test "returns an error when the process is stopped" do
      assert Tai.Venues.Instances.find(@venue) == {:error, :not_found}
    end
  end

  describe ".find_stream/1" do
    test "returns the pid of the stream" do
      {:ok, stream_pid} = Tai.Venues.StreamsSupervisor.start(@stream)

      assert {:ok, pid} = Tai.Venues.Instances.find_stream(@venue)
      assert pid == stream_pid
    end

    test "returns an error when the stream is stopped" do
      assert Tai.Venues.Instances.find_stream(@venue) == {:error, :not_found}
    end
  end

  describe ".stop/1" do
    test "stops the supervised processes for a venue" do
      {:ok, start_pid} = Tai.Venues.Supervisor.start(@venue)
      {:ok, stream_pid} = Tai.Venues.StreamsSupervisor.start(@stream)

      assert Tai.Venues.Instances.stop(@venue) == :ok
      assert Process.alive?(start_pid) == false
      assert Process.alive?(stream_pid) == false
    end

    test "returns an error when the stream or start venue process can't be found" do
      assert Tai.Venues.Instances.stop(@venue) == {:error, :already_stopped}
    end
  end
end
