defmodule Tai.Advisors.Factories.OnePerProduct do
  @behaviour Tai.Advisors.Factory

  @type group :: Tai.AdvisorGroup.t()
  @type spec :: Tai.Advisor.spec()

  @spec advisor_specs(group) :: [spec]
  def advisor_specs(group) do
    group.products
    |> Enum.map(fn product ->
      advisor_id = :"#{product.venue_id}_#{product.symbol}"

      opts = [
        group_id: group.id,
        advisor_id: advisor_id,
        products: [product],
        config: group.config
      ]

      {group.advisor, opts}
    end)
  end
end
