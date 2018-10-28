defmodule Tai.Advisors.Factories.OnePerVenueAndProduct do
  @behaviour Tai.Advisors.Factory

  def advisor_specs(%Tai.AdvisorGroup{} = group, product_symbols_by_venue)
      when is_map(product_symbols_by_venue) do
    product_symbols_by_venue
    |> Enum.reduce(
      [],
      fn {venue_id, product_symbols}, acc ->
        product_symbols
        |> Enum.reduce(
          acc,
          fn symbol, acc ->
            spec = build_spec(group, venue_id, symbol)
            [spec | acc]
          end
        )
      end
    )
    |> Enum.reverse()
  end

  def build_spec(group, venue_id, symbol) do
    advisor_id = :"#{venue_id}_#{symbol}"
    order_books = Map.put(%{}, venue_id, [symbol])
    opts = [group_id: group.id, advisor_id: advisor_id, order_books: order_books, store: %{}]
    {group.advisor, opts}
  end
end
