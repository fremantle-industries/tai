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

  @test_adapters Tai.TestSupport.Helpers.test_venue_adapters()

  @test_adapters
  |> Enum.filter(fn adapter -> adapter.id != :bitmex end)
  |> Enum.map(fn adapter ->
    @adapter adapter
    @account_id adapter.accounts |> Map.keys() |> List.first()

    test "#{adapter.id} returns a list of asset balances" do
      setup_adapter(@adapter.id)

      use_cassette "exchange_adapters/shared/asset_balances/#{@adapter.id}/success" do
        assert {:ok, balances} = Tai.Venue.asset_balances(@adapter, @account_id)
        assert Enum.count(balances) > 0
        assert [%Tai.Venues.AssetBalance{} = balance | _] = balances
        assert balance.exchange_id == @adapter.id
        assert balance.account_id == @account_id
        assert Decimal.cmp(balance.free, Decimal.new(0)) != :lt
        assert Decimal.cmp(balance.locked, Decimal.new(0)) != :lt
      end
    end
  end)

  def setup_adapter(:mock) do
    Tai.TestSupport.Mocks.Responses.AssetBalances.for_exchange_and_account(
      :mock,
      :main,
      [
        %{asset: :btc, free: Decimal.new("0.1"), locked: Decimal.new("0.2")},
        %{asset: :ltc, free: Decimal.new("0.3"), locked: Decimal.new("0.4")}
      ]
    )
  end

  def setup_adapter(_), do: nil
end
