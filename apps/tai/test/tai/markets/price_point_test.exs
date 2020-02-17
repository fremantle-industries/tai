defmodule Tai.Markets.PricePointTest do
  use ExUnit.Case, async: true

  test "implements Access behaviour for price and size" do
    price_point = %Tai.Markets.PricePoint{price: 100, size: 2}

    assert price_point[:price] == 100
    assert price_point[:size] == 2
    assert price_point[:i_dont_exist] == nil
  end
end
