defmodule Tai.Venues.Adapters.AssetBalancesTest do
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

  @test_venues Tai.TestSupport.Helpers.test_venue_adapters_asset_balances()

  @test_venues
  |> Enum.map(fn {_, venue} ->
    @venue venue
    @credential_id venue.credentials |> Map.keys() |> List.first()

    test "#{venue.id} returns a list of asset balances" do
      setup_venue(@venue.id)

      use_cassette "venue_adapters/shared/asset_balances/#{@venue.id}/success" do
        assert {:ok, balances} = Tai.Venues.Client.asset_balances(@venue, @credential_id)
        assert Enum.count(balances) > 0
        assert [%Tai.Venues.AssetBalance{} = balance | _] = balances
        assert balance.venue_id == @venue.id
        assert balance.credential_id == @credential_id
        assert Decimal.cmp(balance.free, Decimal.new(0)) != :lt
        assert Decimal.cmp(balance.locked, Decimal.new(0)) != :lt
      end
    end
  end)

  def setup_venue(:mock) do
    Tai.TestSupport.Mocks.Responses.AssetBalances.for_venue_and_credential(
      :mock,
      :main,
      [
        %{asset: :btc, free: Decimal.new("0.1"), locked: Decimal.new("0.2")},
        %{asset: :ltc, free: Decimal.new("0.3"), locked: Decimal.new("0.4")}
      ]
    )
  end

  def setup_venue(_), do: nil
end
