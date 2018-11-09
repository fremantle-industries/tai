defmodule Tai.Advisors.Factories.OnePerVenueAndProduct do
  @behaviour Tai.Advisors.Factory

  def advisor_specs(%Tai.AdvisorGroup{} = group, products) when is_list(products) do
    products
    |> Enum.map(fn product ->
      advisor_id = :"#{product.exchange_id}_#{product.symbol}"
      order_books = %{} |> Map.put(product.exchange_id, [product.symbol])

      opts = [
        group_id: group.id,
        advisor_id: advisor_id,
        order_books: order_books,
        config: group.config
      ]

      {group.advisor, opts}
    end)
  end
end
