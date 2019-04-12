defmodule Tai.Venues.Adapters.MakerTakerFeesTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    start_supervised!(Tai.TestSupport.Mocks.Server)
    HTTPoison.start()
    :ok
  end

  @test_adapters Tai.TestSupport.Helpers.test_venue_adapters_maker_taker_fees()

  @test_adapters
  |> Enum.map(fn {_, adapter} ->
    @adapter adapter
    @account_id adapter.accounts |> Map.keys() |> List.first()

    test "#{adapter.id} returns a list of asset balances" do
      setup_adapter(@adapter.id)

      use_cassette "exchange_adapters/shared/maker_taker_fees/#{@adapter.id}/success" do
        assert {:ok, fees} = Tai.Venue.maker_taker_fees(@adapter, @account_id)
        assert {%Decimal{} = maker, %Decimal{} = taker} = fees
      end
    end
  end)

  def setup_adapter(:mock) do
    Tai.TestSupport.Mocks.Responses.MakerTakerFees.for_exchange_and_account(
      :mock,
      :main,
      {Decimal.new("0.001"), Decimal.new("0.001")}
    )
  end

  def setup_adapter(_), do: nil
end
