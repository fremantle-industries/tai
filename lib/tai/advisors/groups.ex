defmodule Tai.Advisors.Groups do
  alias Tai.Advisors.Groups

  @type product :: Tai.Venues.Product.t()
  @type advisor_group :: Tai.AdvisorGroup.t()
  @type provider :: Groups.RichConfig.provider()

  @spec from_config(map, provider) :: {:ok, [advisor_group]} | {:error, map}
  def from_config(advisor_groups, provider \\ Groups.RichConfig) do
    venue_indexed_symbols = Tai.Transforms.ProductSymbolsByVenue.all(provider.products)
    groups = advisor_groups |> Enum.map(&build(&1, provider, venue_indexed_symbols))
    errors = groups |> Enum.reduce(%{}, &validate/2)

    if Enum.empty?(errors), do: {:ok, groups}, else: {:error, errors}
  end

  defp build({id, group_config}, provider, venue_indexed_symbols) do
    products_query = group_config |> Keyword.get(:products, "")
    filtered_venue_indexed_symbols = Juice.squeeze(venue_indexed_symbols, products_query)
    filtered_products = filtered_venue_indexed_symbols |> filter_products(provider.products)
    rich_config = group_config |> parse_group_config(provider)

    %Tai.AdvisorGroup{
      id: id,
      start_on_boot: !!(group_config |> Keyword.get(:start_on_boot)),
      advisor: group_config |> Keyword.get(:advisor),
      factory: group_config |> Keyword.get(:factory),
      products: filtered_products,
      config: rich_config,
      trades: group_config |> Keyword.get(:trades, [])
    }
  end

  defp parse_group_config(group_config, provider) do
    group_config
    |> Keyword.get(:config, %{})
    |> case do
      {s, c} -> struct!(s, c |> Groups.RichConfig.parse(provider))
      c -> c |> Groups.RichConfig.parse(provider)
    end
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
