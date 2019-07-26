defmodule Tai.Transforms.ProductSymbolsByVenueTest do
  use ExUnit.Case, async: false
  doctest Tai.Transforms.ProductSymbolsByVenue

  import Tai.TestSupport.Mock

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  test ".all returns a map keyed by venue with a list product symbols" do
    assert Tai.Transforms.ProductSymbolsByVenue.all() == %{}

    mock_product(%{
      venue_id: :venue_a,
      symbol: :btc_usdt
    })

    mock_product(%{
      venue_id: :venue_a,
      symbol: :eth_usdt
    })

    mock_product(%{
      venue_id: :venue_b,
      symbol: :btc_usdt
    })

    mock_product(%{
      venue_id: :venue_b,
      symbol: :ltc_usdt
    })

    assert %{
             venue_a: venue_a_products,
             venue_b: venue_b_products
           } = Tai.Transforms.ProductSymbolsByVenue.all()

    assert Enum.member?(venue_a_products, :btc_usdt)
    assert Enum.member?(venue_a_products, :eth_usdt)
    refute Enum.member?(venue_a_products, :ltc_usdt)
    assert Enum.member?(venue_b_products, :btc_usdt)
    assert Enum.member?(venue_b_products, :ltc_usdt)
    refute Enum.member?(venue_b_products, :eth_usdt)
  end
end
