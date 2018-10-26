defmodule Tai.VenueAdapters.Poloniex.ProductStatusTest do
  use ExUnit.Case, async: true

  describe "#normalize" do
    test "returns an ok tuple for a supported status" do
      assert Tai.VenueAdapters.Poloniex.ProductStatus.normalize("0") ==
               {:ok, Tai.Exchanges.ProductStatus.trading()}

      assert Tai.VenueAdapters.Poloniex.ProductStatus.normalize("1") ==
               {:ok, Tai.Exchanges.ProductStatus.halt()}
    end

    test "returns an error tuple for an unsupported status" do
      assert Tai.VenueAdapters.Binance.ProductStatus.normalize("UNSUPPORTED") ==
               {:error, :unknown_status}
    end
  end
end
