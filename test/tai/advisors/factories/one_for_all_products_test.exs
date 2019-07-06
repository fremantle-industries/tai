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
    specs = OneForAllProducts.advisor_specs(@group_with_products)

    assert Enum.count(specs) == 1
    assert %Tai.Advisors.Spec{} = spec = specs |> List.first()
    assert spec.group_id == :group_a
    assert spec.advisor_id == :main
    assert spec.config == %{hello: :world}
    assert Enum.count(spec.products) == 2
    assert spec.products == @products
  end
end
