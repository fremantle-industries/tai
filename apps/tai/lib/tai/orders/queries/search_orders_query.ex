defmodule Tai.Orders.Queries.SearchOrdersQuery do
  require Ecto.Query
  import Ecto.Query

  @type search_term :: String.t() | nil

  @spec call(search_term) :: Ecto.Query.t()
  def call(search_term) do
    query = from(Tai.Orders.Order, order_by: [asc: :inserted_at])

    if search_term != nil do
      where(
        query,
        [o],
        like(o.venue_order_id, ^"%#{search_term}%") or
          like(o.venue, ^"%#{search_term}%") or
          like(o.credential, ^"%#{search_term}%") or
          like(o.product_symbol, ^"%#{search_term}%") or
          like(o.venue_product_symbol, ^"%#{search_term}%")
      )
    else
      query
    end
  end
end
