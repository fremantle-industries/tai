defmodule Tai.VenueAdapters.Gdax.ProductStatusTest do
  use ExUnit.Case, async: true

  describe "#normalize" do
    test "returns an ok tuple for a supported status" do
      assert Tai.VenueAdapters.Gdax.ProductStatus.normalize("online") ==
               {:ok, Tai.Exchanges.ProductStatus.trading()}
    end

    test "returns an error tuple for and unsupported status" do
      assert Tai.VenueAdapters.Gdax.ProductStatus.normalize("UNSUPPORTED") ==
               {:error, :unknown_status}
    end
  end
end
