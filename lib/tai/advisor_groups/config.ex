defmodule Tai.AdvisorGroups.Config do
  @type config :: Tai.Config.t()
  @type product :: Tai.Venues.Product.t()
  @type advisor_group :: Tai.AdvisorGroup.t()

  @spec parse_groups(config, [product]) :: {:ok, [advisor_group]} | {:error, map}
  def parse_groups(%Tai.Config{} = config, products \\ Tai.Venues.ProductStore.all()) do
    venue_indexed_symbols = Tai.Transforms.ProductSymbolsByVenue.all(products)
    groups = config.advisor_groups |> Enum.map(&build(&1, venue_indexed_symbols, products))
    errors = groups |> Enum.reduce(%{}, &validate/2)

    if Enum.empty?(errors), do: {:ok, groups}, else: {:error, errors}
  end

  defp build({id, config}, venue_indexed_symbols, products) do
    products_query = config |> Keyword.get(:products, "")
    filtered_venue_indexed_symbols = Juice.squeeze(venue_indexed_symbols, products_query)
    filtered_products = filtered_venue_indexed_symbols |> filter_products(products)

    %Tai.AdvisorGroup{
      id: id,
      start_on_boot: !!(config |> Keyword.get(:start_on_boot)),
      advisor: config |> Keyword.get(:advisor),
      factory: config |> Keyword.get(:factory),
      products: filtered_products,
      config: config |> Keyword.get(:config, %{}),
      trades: config |> Keyword.get(:trades, [])
    }
  end

  defp filter_products(filtered_venue_indexed_symbols, products) do
    filtered_venue_indexed_symbols
    |> Enum.flat_map(fn {venue_id, product_symbols} ->
      products
      |> Enum.filter(fn p ->
        p.venue_id == venue_id && Enum.member?(product_symbols, p.symbol)
      end)
    end)
  end

  defp validate(group, errors) do
    if Vex.valid?(group) do
      errors
    else
      validation_errors =
        group
        |> Vex.errors()
        |> Enum.map(fn {:error, k, _, m} -> {k, m} end)

      Map.put(errors, group.id, validation_errors)
    end
  end
end
