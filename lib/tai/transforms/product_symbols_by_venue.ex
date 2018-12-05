defmodule Tai.Transforms.ProductSymbolsByVenue do
  @moduledoc """
  Transforms a list of products to a map of product symbols by venue
  """

  @type product :: Tai.Exchanges.Product.t()

  @spec all :: map
  @spec all([product]) :: map
  def all(products \\ Tai.Venues.ProductStore.all()) do
    products
    |> Enum.reduce(
      %{},
      fn p, acc ->
        venue_products = Map.get(acc, p.exchange_id, [])
        Map.put(acc, p.exchange_id, [p.symbol | venue_products])
      end
    )
  end
end
