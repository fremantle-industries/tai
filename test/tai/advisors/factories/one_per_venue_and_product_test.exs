defmodule Tai.Advisors.Factories.OnePerVenueAndProductTest do
  use ExUnit.Case, async: true
  alias Tai.Advisors.Factories.OnePerVenueAndProduct

  @product struct(Tai.Venues.Product, %{venue_id: :venue_a, symbol: :btc_usdt})
  @group_with_products struct(Tai.AdvisorGroup, %{
                         id: :group_a,
                         advisor: MyAdvisor,
                         factory: Tai.Advisors.Factories.OnePerVenueAndProduct,
                         products: [@product],
                         config: %{hello: :world}
                       })

  test "returns an advisor spec for each product on the given venues" do
    assert [spec | []] = OnePerVenueAndProduct.advisor_specs(@group_with_products)

    assert {MyAdvisor, opts} = spec
    assert Keyword.fetch!(opts, :group_id) == :group_a
    assert Keyword.fetch!(opts, :advisor_id) == :venue_a_btc_usdt
    assert Keyword.fetch!(opts, :config) == %{hello: :world}
    assert Keyword.fetch!(opts, :products) |> List.first() == @product
  end
end
