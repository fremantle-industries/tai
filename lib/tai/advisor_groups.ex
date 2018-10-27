defmodule Tai.AdvisorGroups do
  @type config :: Tai.Config.t()
  @type advisor_group :: Tai.AdvisorGroup.t()
  @type advisor_spec :: {atom, [group_id: atom, advisor_id: atom, order_books: map, store: map]}

  @spec parse_config(config :: config) :: {:ok, [advisor_group]} | {:error, map}
  def parse_config(%Tai.Config{advisor_groups: advisor_groups}) do
    results =
      advisor_groups
      |> Enum.reduce(
        %{groups: [], errors: %{}},
        fn {id, config}, acc ->
          errors = []

          factory = Keyword.get(config, :factory)
          errors = if factory == nil, do: [:factory_not_present | errors], else: errors

          products = Keyword.get(config, :products)
          errors = if products == nil, do: [:products_not_present | errors], else: errors

          store = Keyword.get(config, :store, %{})

          if Enum.empty?(errors) do
            group = %Tai.AdvisorGroup{
              id: id,
              factory: factory,
              products: products,
              store: store
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

  @spec build_specs(config :: config, product_symbols_by_exchange :: map) ::
          {:ok, [advisor_spec]} | {:error, map}
  def build_specs(
        %Tai.Config{} = config,
        product_symbols_by_exchange \\ Tai.Queries.ProductSymbolsByExchange.all()
      ) do
    with {:ok, groups} <- config |> Tai.AdvisorGroups.parse_config() do
      specs =
        Enum.reduce(
          groups,
          [],
          fn group, acc ->
            products = Juice.squeeze(product_symbols_by_exchange, group.products)
            acc ++ group.factory.advisor_specs(group, products)
          end
        )

      {:ok, specs}
    end
  end

  @spec build_specs_for_group(
          config :: config,
          group_id :: atom,
          product_symbols_by_exchange :: map
        ) :: {:ok, [advisor_spec]} | {:error, map}
  def build_specs_for_group(
        %Tai.Config{} = config,
        group_id,
        product_symbols_by_exchange \\ Tai.Queries.ProductSymbolsByExchange.all()
      ) do
    with {:ok, specs} <- build_specs(config, product_symbols_by_exchange) do
      filtered_specs =
        Enum.filter(specs, fn {_, opts} -> Keyword.get(opts, :group_id) == group_id end)

      {:ok, filtered_specs}
    end
  end

  @spec build_specs_for_advisor(
          config :: config,
          group_id :: atom,
          advisor_id :: atom,
          product_symbols_by_exchange :: map
        ) :: {:ok, [advisor_spec]} | {:error, map}
  def build_specs_for_advisor(
        %Tai.Config{} = config,
        group_id,
        advisor_id,
        product_symbols_by_exchange \\ Tai.Queries.ProductSymbolsByExchange.all()
      ) do
    with {:ok, specs} <- build_specs(config, product_symbols_by_exchange) do
      filtered_specs =
        specs
        |> Enum.filter(fn {_, opts} -> Keyword.get(opts, :group_id) == group_id end)
        |> Enum.filter(fn {_, opts} -> Keyword.get(opts, :advisor_id) == advisor_id end)

      {:ok, filtered_specs}
    end
  end
end
