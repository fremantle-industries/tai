defmodule Examples.Advisors.FillOrKillOrders.Factory do
  @type advisor_group :: Tai.AdvisorGroup.t()

  @spec advisor_specs(advisor_group :: atom, products_by_exchange :: map) :: [
          [group_id: atom, advisor_id: atom, order_books: map, store: map]
        ]
  def advisor_specs(%Tai.AdvisorGroup{} = group, products_by_exchange)
      when is_map(products_by_exchange) do
    products_by_exchange
    |> Enum.reduce(
      [],
      fn {exchange_id, product_symbols}, acc ->
        product_symbols
        |> Enum.reduce(
          acc,
          fn symbol, acc ->
            spec = {
              Examples.Advisors.FillOrKillOrders.Advisor,
              [
                group_id: group.id,
                advisor_id: :"#{exchange_id}_#{symbol}",
                order_books: Map.put(%{}, exchange_id, [symbol]),
                store: %{}
              ]
            }

            [spec | acc]
          end
        )
      end
    )
    |> Enum.reverse()
  end
end
