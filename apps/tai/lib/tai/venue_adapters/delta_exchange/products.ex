defmodule Tai.VenueAdapters.DeltaExchange.Products do
  alias Tai.VenueAdapters.DeltaExchange

  def products(venue_id) do
    with {:ok, venue_products} <- ExDeltaExchange.Products.List.get() do
      products = venue_products |> Enum.map(& DeltaExchange.Product.build(&1, venue_id))
      {:ok, products}
    end
  end
end
