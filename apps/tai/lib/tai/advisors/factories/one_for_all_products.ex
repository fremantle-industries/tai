defmodule Tai.Advisors.Factories.OneForAllProducts do
  @moduledoc """
  Advisor factory for sharing all subscribed products.

  Use this to receive order book updates from all subscribed products in that group.
  """
  @behaviour Tai.Advisors.Factory

  @type group :: Tai.AdvisorGroup.t()
  @type spec :: Tai.Advisors.Spec.t()

  @spec advisor_specs(group) :: [spec]
  def advisor_specs(group) do
    %Tai.Advisors.Spec{
      mod: group.advisor,
      start_on_boot: group.start_on_boot,
      restart: group.restart,
      shutdown: group.shutdown,
      group_id: group.id,
      advisor_id: :main,
      products: group.products,
      config: group.config
    }
    |> List.wrap()
  end
end
