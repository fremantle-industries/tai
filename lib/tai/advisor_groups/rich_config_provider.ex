defmodule Tai.AdvisorGroups.RichConfigProvider do
  @type product :: Tai.Venues.Product.t()
  @type fee :: Tai.Venues.FeeInfo.t()

  @callback products() :: [product]
  @callback fees() :: [fee]

  @spec products() :: [product]
  def products, do: Tai.Venues.ProductStore.all()

  @spec fees() :: [fee]
  def fees, do: Tai.Venues.FeeStore.all()
end
