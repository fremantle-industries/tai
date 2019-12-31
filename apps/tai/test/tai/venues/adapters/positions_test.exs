defmodule Tai.Venues.Adapters.PositionsTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    start_supervised!(Tai.TestSupport.Mocks.Server)
    HTTPoison.start()
    :ok
  end

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  @test_venues Tai.TestSupport.Helpers.test_venue_adapters_with_positions()

  @test_venues
  |> Enum.map(fn {_, venue} ->
    @venue venue
    @credential_id venue.credentials |> Map.keys() |> List.first()

    test "#{venue.id} returns a list of positions" do
      use_cassette "venue_adapters/shared/positions/#{@venue.id}/success" do
        assert {:ok, positions} = Tai.Venues.Client.positions(@venue, @credential_id)
        assert Enum.count(positions) > 0
        assert [position | _] = positions
        assert position.venue_id == @venue.id
        assert position.credential_id == @credential_id
        assert position.product_symbol != nil
        assert Enum.all?(positions, fn %type{} -> type == Tai.Trading.Position end) == true
      end
    end
  end)
end
