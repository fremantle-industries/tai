defmodule Tai.AdvisorGroups do
  def specs do
    Tai.AdvisorGroup.parse_configs()
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
