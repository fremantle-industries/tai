defmodule Tai.Products.Queries.ProductSymbolsByVenue do
  def call do
    Tai.Venues.ProductStore.all()
    |> Enum.reduce(
      %{},
      fn p, acc ->
        venue_products = Map.get(acc, p.venue_id, [])
        Map.put(acc, p.venue_id, [p.symbol | venue_products])
      end
    )
  end
end
