defmodule Tai.Advisors.Factories.OnePerProduct do
  @behaviour Tai.Advisors.Factory

  @type group :: Tai.AdvisorGroup.t()
  @type spec :: Tai.Advisors.Spec.t()

  @spec advisor_specs(group) :: [spec]
  def advisor_specs(group) do
    group.products
    |> Enum.map(fn product ->
      %Tai.Advisors.Spec{
        mod: group.advisor,
        start_on_boot: group.start_on_boot,
        group_id: group.id,
        advisor_id: :"#{product.venue_id}_#{product.symbol}",
        products: [product],
        config: group.config
      }
    end)
  end
end
