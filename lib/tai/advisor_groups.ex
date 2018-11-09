defmodule Tai.AdvisorGroups do
  @type config :: Tai.Config.t()
  @type advisor_group :: Tai.AdvisorGroup.t()
  @type advisor_spec :: {atom, [group_id: atom, advisor_id: atom, order_books: map, store: map]}
  @type product :: Tai.Exchanges.Product.t()

  @spec parse_config(config :: config) :: {:ok, [advisor_group]} | {:error, map}
  def parse_config(%Tai.Config{advisor_groups: advisor_groups}) do
    results =
      advisor_groups
      |> Enum.reduce(
        %{groups: [], errors: %{}},
        fn {id, config}, acc ->
          errors = []

          advisor = Keyword.get(config, :advisor)
          errors = if advisor == nil, do: [:advisor_not_present | errors], else: errors

          factory = Keyword.get(config, :factory)
          errors = if factory == nil, do: [:factory_not_present | errors], else: errors

          products = Keyword.get(config, :products)
          errors = if products == nil, do: [:products_not_present | errors], else: errors

          per_advisor_config = Keyword.get(config, :config, %{})

          if Enum.empty?(errors) do
            group = %Tai.AdvisorGroup{
              id: id,
              advisor: advisor,
              factory: factory,
              products: products,
              config: per_advisor_config
            }

            new_groups = acc.groups ++ [group]
            Map.put(acc, :groups, new_groups)
          else
            group_errors = Map.put(acc.errors, id, errors)
            Map.put(acc, :errors, group_errors)
          end
        end
      )

    if Enum.empty?(results.errors) do
      {:ok, results.groups}
    else
      {:error, results.errors}
    end
  end

  @spec build_specs(config :: config, products :: [product]) ::
          {:ok, [advisor_spec]} | {:error, map}
  def build_specs(
        %Tai.Config{} = config,
        products \\ Tai.Exchanges.ProductStore.all()
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
                  p.exchange_id == venue_id && Enum.member?(product_symbols, p.symbol)
                end)
              end)

            acc ++ group.factory.advisor_specs(group, filtered_products)
          end
        )

      {:ok, specs}
    end
  end

  @spec build_specs_for_group(
          config :: config,
          group_id :: atom,
          products :: [product]
        ) :: {:ok, [advisor_spec]} | {:error, map}
  def build_specs_for_group(
        %Tai.Config{} = config,
        group_id,
        products \\ Tai.Exchanges.ProductStore.all()
      ) do
    with {:ok, specs} <- build_specs(config, products) do
      filtered_specs =
        Enum.filter(
          specs,
          fn {_, opts} -> Keyword.get(opts, :group_id) == group_id end
        )

      {:ok, filtered_specs}
    end
  end

  @spec build_specs_for_advisor(
          config :: config,
          group_id :: atom,
          advisor_id :: atom,
          products :: [product]
        ) :: {:ok, [advisor_spec]} | {:error, map}
  def build_specs_for_advisor(
        %Tai.Config{} = config,
        group_id,
        advisor_id,
        products \\ Tai.Exchanges.ProductStore.all()
      ) do
    with {:ok, specs} <- build_specs(config, products) do
      filtered_specs =
        specs
        |> Enum.filter(fn {_, opts} -> Keyword.get(opts, :group_id) == group_id end)
        |> Enum.filter(fn {_, opts} -> Keyword.get(opts, :advisor_id) == advisor_id end)

      {:ok, filtered_specs}
    end
  end
end
