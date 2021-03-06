defmodule Tai.Commander.EstimatedFundingRates do
  @type estimated_funding_rate :: Tai.Venues.EstimatedFundingRate.t()

  @spec get :: [estimated_funding_rate]
  def get do
    Tai.Venues.EstimatedFundingRateStore.all()
    |> Enum.sort(&(&1.venue < &2.venue))
  end
end
