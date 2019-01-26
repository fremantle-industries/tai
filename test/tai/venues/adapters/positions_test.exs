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

  @test_adapters Tai.TestSupport.Helpers.test_venue_adapters_with_positions()

  @test_adapters
  |> Enum.map(fn {_, adapter} ->
    @adapter adapter
    @account_id adapter.accounts |> Map.keys() |> List.first()

    test "#{adapter.id} returns a list of positions" do
      use_cassette "venue_adapters/shared/positions/#{@adapter.id}/success" do
        assert {:ok, positions} = Tai.Venue.positions(@adapter, @account_id)
        assert Enum.count(positions) > 0
        assert [%Tai.Trading.Position{} = position | _] = positions
        assert position.venue_id == @adapter.id
        assert position.account_id == @account_id
        assert position.open == false
        assert %Decimal{} = position.qty
        assert %Decimal{} = position.init_margin
        assert %Decimal{} = position.init_margin_req
        assert %Decimal{} = position.maint_margin
        assert %Decimal{} = position.maint_margin_req
        assert %Decimal{} = position.realised_pnl
        assert %Decimal{} = position.unrealised_pnl
      end
    end
  end)
end
