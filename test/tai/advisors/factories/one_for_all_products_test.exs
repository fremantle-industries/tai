defmodule Tai.Advisors.Factories.OneForAllProductsTest do
  use ExUnit.Case, async: true
  alias Tai.Advisors.Factories.OneForAllProducts

  @products [
    struct(Tai.Venues.Product, %{venue_id: :venue_a, symbol: :btc_usdt}),
    struct(Tai.Venues.Product, %{venue_id: :venue_b, symbol: :etc_usdt})
  ]
  @group_with_products struct(Tai.AdvisorGroup, %{
                         id: :group_a,
                         advisor: MyAdvisor,
                         factory: OneForAllProducts,
                         products: @products,
                         config: %{hello: :world}
                       })

  test "returns one advisor spec for all products in one advisor group" do
    assert [spec] = OneForAllProducts.advisor_specs(@group_with_products)

    assert {MyAdvisor, opts} = spec
    assert Keyword.fetch!(opts, :group_id) == :group_a
    assert Keyword.fetch!(opts, :advisor_id) == :main
    assert Keyword.fetch!(opts, :config) == %{hello: :world}
    assert Keyword.fetch!(opts, :products) == @products
  end
end
