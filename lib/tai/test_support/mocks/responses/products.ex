defmodule Tai.TestSupport.Mocks.Responses.Products do
  def for_venue(venue_id, products_attrs) do
    products =
      products_attrs
      |> Enum.map(fn attrs ->
        struct(
          Tai.Venues.Product,
          Map.merge(%{exchange_id: venue_id, venue_id: venue_id}, attrs)
        )
      end)

    key = Tai.VenueAdapters.Mock.products_response_key(venue_id)
    :ok = Tai.TestSupport.Mocks.Server.insert(key, products)

    :ok
  end
end
