defmodule Tai.TestSupport.Mocks.Responses.Products do
  def for_venue(venue_id, products_attrs) do
    products =
      products_attrs
      |> Enum.map(fn attrs ->
        struct(
          Tai.Venues.Product,
          Map.merge(%{venue_id: venue_id}, attrs)
        )
      end)

    {:products, venue_id}
    |> Tai.TestSupport.Mocks.Server.insert(products)
  end
end
