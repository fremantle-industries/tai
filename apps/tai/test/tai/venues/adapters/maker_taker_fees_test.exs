defmodule Tai.Venues.Adapters.MakerTakerFeesTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    start_supervised!(Tai.TestSupport.Mocks.Server)
    HTTPoison.start()
    :ok
  end

  @test_venues Tai.TestSupport.Helpers.test_venue_adapters_maker_taker_fees()

  @test_venues
  |> Enum.map(fn {_, venue} ->
    @venue venue
    @credential_id venue.credentials |> Map.keys() |> List.first()

    test "#{venue.id} returns a list of asset balances" do
      setup_adapter(@venue.id)

      use_cassette "venue_adapters/shared/maker_taker_fees/#{@venue.id}/success" do
        assert {:ok, fees} = Tai.Venues.Client.maker_taker_fees(@venue, @credential_id)
        assert {%Decimal{} = maker, %Decimal{} = taker} = fees
      end
    end
  end)

  def setup_adapter(:mock) do
    Tai.TestSupport.Mocks.Responses.MakerTakerFees.for_venue_and_credential(
      :mock,
      :main,
      {Decimal.new("0.001"), Decimal.new("0.001")}
    )
  end

  def setup_adapter(_), do: nil
end
