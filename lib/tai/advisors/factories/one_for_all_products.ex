defmodule Tai.Advisors.Factories.OneForAllProducts do
  @moduledoc """
  Advisor factory for sharing all subscribed products.

  Use this to receive order book updates from all subscribed products in that group.
  """
  @behaviour Tai.Advisors.Factory

  @type group :: Tai.AdvisorGroup.t()
  @type spec :: Tai.Advisor.spec()

  @spec advisor_specs(group) :: [spec]
  def advisor_specs(group) do
    opts = [
      group_id: group.id,
      advisor_id: :main,
      products: group.products,
      config: group.config
    ]

    [{group.advisor, opts}]
  end
end
