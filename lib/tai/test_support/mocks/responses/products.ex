defmodule Tai.TestSupport.Mocks.Responses.Products do
  def for_exchange(exchange_id, products_attrs) do
    products =
      products_attrs
      |> Enum.map(fn attrs ->
        struct(
          Tai.Venues.Product,
          Map.merge(%{exchange_id: exchange_id}, attrs)
        )
      end)

    key = Tai.VenueAdapters.Mock.products_response_key(exchange_id)
    :ok = Tai.TestSupport.Mocks.Server.insert(key, products)

    :ok
  end
end
