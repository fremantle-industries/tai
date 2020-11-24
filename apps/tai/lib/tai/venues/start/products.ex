defmodule Tai.Venues.Start.Products do
  @type venue :: Tai.Venue.t()
  @type product :: Tai.Venues.Product.t()
  @type error_reason :: term

  @spec hydrate(venue) :: {:ok, [product]} | {:error, error_reason}
  def hydrate(venue) do
    venue
    |> fetch
    |> filter
    |> broadcast_result
  end

  defp fetch(venue) do
    try do
      with {:ok, products} <- Tai.Venues.Client.products(venue) do
        {:ok, venue, products}
      else
        {:error, _} = error -> error
      end
    rescue
      e ->
        {:error, {e, __STACKTRACE__}}
    end
  end

  defp filter({:ok, venue, products}) do
    total = Enum.count(products)
    filtered_products = apply_filter(products, venue.products)
    Enum.each(filtered_products, &Tai.Venues.ProductStore.upsert/1)

    {:ok, venue, total, filtered_products}
  end

  defp filter({:error, _} = error), do: error

  defp broadcast_result({:ok, venue, total, filtered_products}) do
    %Tai.Events.HydrateProducts{
      venue_id: venue.id,
      total: total,
      filtered: filtered_products |> Enum.count()
    }
    |> TaiEvents.info()

    {:ok, filtered_products}
  end

  defp broadcast_result({:error, _} = error), do: error

  defp apply_filter(products, {mod, func_name}) do
    apply(mod, func_name, [products])
  end

  defp apply_filter(products, {mod, func_name, args}) do
    apply(mod, func_name, [products] ++ args)
  end

  defp apply_filter(products, query) when is_binary(query) do
    products
    |> index_products()
    |> Juice.squeeze(query)
    |> Map.values()
    |> Enum.uniq()
  end

  defp index_products(products) do
    symbol_products =
      products
      |> Enum.reduce(
        %{},
        fn p, acc -> Map.put(acc, p.symbol, p) end
      )

    alias_products =
      products
      |> Enum.filter(& &1.alias)
      |> Enum.reduce(%{}, fn p, acc ->
        Map.put(acc, "#{p.base}_#{p.quote}_#{p.alias}", p)
      end)

    Map.merge(alias_products, symbol_products)
  end
end
