defmodule Tai.Advisors.Factories.OnePerProduct do
  @behaviour Tai.Advisors.Factory

  @type fleet_config :: Tai.Fleets.FleetConfig.t()
  @type advisor_config :: Tai.Fleets.AdvisorConfig.t()

  @spec advisor_configs(fleet_config) :: [advisor_config]
  def advisor_configs(fleet) do
    config = fleet.config || %{}
    products = Tai.Products.product_symbols_by_venue()
    filtered_products = products |> Juice.squeeze(fleet.quotes)
    quote_keys = build_quote_keys(filtered_products)

    quote_keys
    |> Enum.map(fn {venue, symbol} ->
      %Tai.Fleets.AdvisorConfig{
        advisor_id: :"#{venue}_#{symbol}",
        fleet_id: fleet.id,
        mod: fleet.advisor,
        start_on_boot: fleet.start_on_boot,
        restart: fleet.restart,
        shutdown: fleet.shutdown,
        quote_keys: [{venue, symbol}],
        config: config
      }
    end)
  end

  defp build_quote_keys(filtered_products) do
    filtered_products
    |> Enum.flat_map(fn {v, symbols} ->
      symbols
      |> Enum.map(fn s -> {v, s} end)
    end)
  end
end
