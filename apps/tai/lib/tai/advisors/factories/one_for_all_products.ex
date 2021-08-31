defmodule Tai.Advisors.Factories.OneForAllProducts do
  @moduledoc """
  Advisor factory for sharing all subscribed products.

  Use this to receive order book updates from all subscribed products in that group.
  """

  @behaviour Tai.Advisors.Factory

  @type fleet_config :: Tai.Fleets.FleetConfig.t()
  @type advisor_config :: Tai.Fleets.AdvisorConfig.t()

  @spec advisor_configs(fleet_config) :: [advisor_config]
  def advisor_configs(fleet) do
    config = fleet.config || %{}
    products = Tai.Products.product_symbols_by_venue()
    filtered_products = products |> Juice.squeeze(fleet.quotes)
    quote_keys = build_quote_keys(filtered_products)

    %Tai.Fleets.AdvisorConfig{
      advisor_id: :main,
      fleet_id: fleet.id,
      mod: fleet.advisor,
      start_on_boot: fleet.start_on_boot,
      restart: fleet.restart,
      shutdown: fleet.shutdown,
      quote_keys: quote_keys,
      config: config
    }
    |> List.wrap()
  end

  defp build_quote_keys(filtered_products) do
    filtered_products
    |> Enum.flat_map(fn {v, symbols} ->
      symbols
      |> Enum.map(fn s -> {v, s} end)
    end)
  end
end
