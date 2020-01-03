defmodule Tai.Venues.Adapters.Bitmex.ProductsTest do
  use ExUnit.Case, async: false
  import Mock

  @test_venues Tai.TestSupport.Helpers.test_venue_adapters()

  setup_all do
    venue = @test_venues |> Map.fetch!(:bitmex)
    {:ok, %{venue: venue}}
  end

  test "bubbles errors without the rate limit", %{venue: venue} do
    with_mock HTTPoison, request: fn _url -> {:error, %HTTPoison.Error{reason: :timeout}} end do
      assert Tai.Venues.Client.products(venue) == {:error, :timeout}
    end
  end
end
