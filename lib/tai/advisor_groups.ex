defmodule Tai.AdvisorGroups do
  @type config :: Tai.Config.t()
  @type advisor_group :: Tai.AdvisorGroup.t()

  @spec parse_config(config :: config) :: {:ok, [advisor_group]}
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

          if Enum.empty?(errors) do
            group = %Tai.AdvisorGroup{
              id: id,
              factory: factory,
              products: products
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

  def specs do
    Tai.Config.parse()
    |> Tai.AdvisorGroups.parse_config()
    |> build_specs
  end

  defp build_specs({:ok, groups}) do
    products_by_exchange = Tai.Queries.ProductsByExchange.all()

    groups
    |> Enum.reduce(
      [],
      fn group, acc ->
        products = Juice.squeeze(products_by_exchange, group.products)
        acc ++ group.factory.advisor_specs(group, products)
      end
    )
  end
end
