defmodule Tai.VenueAdapters.Bitmex.ProductTypeTest do
  use ExUnit.Case, async: true
  alias Tai.VenueAdapters.Bitmex

  test ".normalize/1 converts product type" do
    assert Bitmex.ProductType.normalize("FFWCSX") == :swap
    assert Bitmex.ProductType.normalize("FFWCSF") == :swap
    assert Bitmex.ProductType.normalize("IFXXXP") == :spot
    assert Bitmex.ProductType.normalize("FFCCSX") == :future

    assert Bitmex.ProductType.normalize("XXXXXX") == :future, "fallback to future"
  end
end
