defmodule Tai.Queries.ProductSymbolsByExchangeTest do
  use ExUnit.Case, async: false
  doctest Tai.Queries.ProductSymbolsByExchange

  import Tai.TestSupport.Mock

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  test ".all returns a map keyed by exchange with a list product symbols" do
    assert Tai.Queries.ProductSymbolsByExchange.all() == %{}

    mock_product(%{
      exchange_id: :exchange_a,
      symbol: :btc_usdt
    })

    mock_product(%{
      exchange_id: :exchange_a,
      symbol: :eth_usdt
    })

    mock_product(%{
      exchange_id: :exchange_b,
      symbol: :btc_usdt
    })

    mock_product(%{
      exchange_id: :exchange_b,
      symbol: :ltc_usdt
    })

    assert %{
             exchange_a: exchange_a_products,
             exchange_b: exchange_b_products
           } = Tai.Queries.ProductSymbolsByExchange.all()

    assert Enum.member?(exchange_a_products, :btc_usdt)
    assert Enum.member?(exchange_a_products, :eth_usdt)
    refute Enum.member?(exchange_a_products, :ltc_usdt)
    assert Enum.member?(exchange_b_products, :btc_usdt)
    assert Enum.member?(exchange_b_products, :ltc_usdt)
    refute Enum.member?(exchange_b_products, :eth_usdt)
  end
end
