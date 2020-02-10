defmodule Tai.Venues.Adapters.Bitmex.ProductsTest do
  use ExUnit.Case, async: false
  import Mock

  @venue Tai.TestSupport.Helpers.test_venue_adapter(:bitmex)

  test "bubbles errors without the rate limit" do
    with_mock HTTPoison, request: fn _url -> {:error, %HTTPoison.Error{reason: :timeout}} end do
      assert Tai.Venues.Client.products(@venue) == {:error, :timeout}
    end
  end
end
