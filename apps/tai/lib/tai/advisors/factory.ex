defmodule Tai.Advisors.Factory do
  @type fleet_config :: Tai.Fleets.FleetConfig.t()
  @type advisor_config :: Tai.Fleets.AdvisorConfig.t()

  @callback advisor_configs(fleet_config) :: [advisor_config]

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour Tai.Advisors.Factory

      defp build_venue_product_keys(market_streams) do
        Tai.Products.product_symbols_by_venue()
        |> Juice.squeeze(market_streams)
        |> Enum.flat_map(fn {v, symbols} ->
          symbols
          |> Enum.map(fn s -> {v, s} end)
        end)
      end
    end
  end
end
