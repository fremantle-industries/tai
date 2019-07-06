defmodule Tai.Advisors.Factories.OnePerProductTest do
  use ExUnit.Case, async: true
  alias Tai.Advisors.Factories.OnePerProduct

  @product struct(Tai.Venues.Product, %{venue_id: :venue_a, symbol: :btc_usdt})
  @group_with_products struct(Tai.AdvisorGroup, %{
                         id: :group_a,
                         advisor: MyAdvisor,
                         factory: Tai.Advisors.Factories.OnePerProduct,
                         products: [@product],
                         config: %{hello: :world}
                       })

  test "returns an advisor spec for each product in the group" do
    specs = OnePerProduct.advisor_specs(@group_with_products)

    assert Enum.count(specs) == 1
    assert %Tai.Advisors.Spec{} = spec = specs |> List.first()
    assert spec.mod == MyAdvisor
    assert spec.group_id == :group_a
    assert spec.advisor_id == :venue_a_btc_usdt
    assert spec.config == %{hello: :world}
    assert Enum.count(spec.products) == 1
    assert spec.products |> List.first() == @product
  end
end
