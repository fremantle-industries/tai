defmodule Tai.AdvisorGroups.BuildSpecs do
  @type config :: Tai.Config.t()
  @type advisor_spec :: {atom, [group_id: atom, advisor_id: atom, order_books: map, store: map]}
  @type product :: Tai.Venues.Product.t()

  @spec build_specs(config, [product]) :: {:ok, [advisor_spec]} | {:error, map}
  def build_specs(
        %Tai.Config{} = config,
        products \\ Tai.Venues.ProductStore.all()
      ) do
    product_symbols_by_exchange = Tai.Transforms.ProductSymbolsByVenue.all(products)

    with {:ok, groups} <- config |> Tai.AdvisorGroups.parse_config() do
      specs =
        Enum.reduce(
          groups,
          [],
          fn group, acc ->
            filtered_product_symbols_by_exchange =
              Juice.squeeze(product_symbols_by_exchange, group.products)

            filtered_products =
              filtered_product_symbols_by_exchange
              |> Enum.flat_map(fn {venue_id, product_symbols} ->
                products
                |> Enum.filter(fn p ->
                  p.venue_id == venue_id && Enum.member?(product_symbols, p.symbol)
                end)
              end)

            acc ++ group.factory.advisor_specs(group, filtered_products)
          end
        )

      {:ok, specs}
    end
  end
end
