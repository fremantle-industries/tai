defmodule Tai.Exchanges.Boot.Products do
  @type adapter :: Tai.Exchanges.Adapter.t()
  @type product :: Tai.Exchanges.Product.t()

  @spec hydrate(adapter :: adapter) ::
          {:ok, filtered_products :: [product]} | {:error, reason :: term}
  def hydrate(adapter) do
    with {:ok, all_products} <- Tai.Exchanges.Exchange.products(adapter) do
      filtered_products = filter(all_products, adapter.products)
      Enum.each(filtered_products, &Tai.Exchanges.ProductStore.upsert/1)
      {:ok, filtered_products}
    else
      {:error, _} = error -> error
    end
  end

  def filter(all_products, filters) do
    all_products
    |> Enum.reduce(
      %{},
      fn p, acc -> Map.put(acc, p.symbol, p) end
    )
    |> Juice.squeeze(filters)
    |> Map.values()
  end
end
