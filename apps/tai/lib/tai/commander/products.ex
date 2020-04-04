defmodule Tai.Commander.Products do
  @type product :: Tai.Venues.Product.t()

  @spec get :: [product]
  def get do
    Tai.Venues.ProductStore.all()
    |> Enum.sort(&(&1.symbol < &2.symbol))
  end
end
