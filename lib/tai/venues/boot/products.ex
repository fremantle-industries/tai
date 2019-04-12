defmodule Tai.Venues.Boot.Products do
  @type adapter :: Tai.Venues.Adapter.t()
  @type product :: Tai.Venues.Product.t()

  @spec hydrate(adapter) :: {:ok, [product]} | {:error, reason :: term}
  def hydrate(adapter) do
    with {:ok, all_products} <- Tai.Venue.products(adapter) do
      filtered_products = filter(all_products, adapter.products)
      Enum.each(filtered_products, &Tai.Venues.ProductStore.upsert/1)

      Tai.Events.info(%Tai.Events.HydrateProducts{
        venue_id: adapter.id,
        total: all_products |> Enum.count(),
        filtered: filtered_products |> Enum.count()
      })

      {:ok, filtered_products}
    else
      {:error, _} = error -> error
    end
  end

  defp filter(all_products, filters) do
    all_products
    |> Enum.reduce(
      %{},
      fn p, acc -> Map.put(acc, p.symbol, p) end
    )
    |> Juice.squeeze(filters)
    |> Map.values()
  end
end
