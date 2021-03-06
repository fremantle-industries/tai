defmodule Tai.Commander.FundingRates do
  @type funding_rate :: Tai.Venues.FundingRate.t()

  @spec get :: [funding_rate]
  def get do
    Tai.Venues.FundingRateStore.all()
    |> Enum.sort(&(&1.venue < &2.venue))
  end
end
