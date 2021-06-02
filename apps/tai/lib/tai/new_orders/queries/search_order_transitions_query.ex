defmodule Tai.NewOrders.Queries.SearchOrderTransitionsQuery do
  require Ecto.Query
  import Ecto.Query
  alias Tai.NewOrders.{Order, OrderTransition}

  @type order_client_id :: Order.client_id
  @type search_term :: String.t() | nil

  @spec call(order_client_id, search_term) :: Ecto.Query.t()
  def call(order_client_id, _search_term) do
    query = from(
      t in OrderTransition,
      where: t.order_client_id == ^order_client_id,
      order_by: [asc: :inserted_at]
    )

    # if search_term != nil do
    #   where(
    #     query,
    #     [t],
    #     t.client_id == order_client_id
    #     # TODO: Figure out how to search JSON/map field in ecto
    #     # or like(t.venue_order_id, ^"%#{search_term}%")
    #     # or like(t.venue, ^"%#{search_term}%")
    #     # or like(t.credential, ^"%#{search_term}%")
    #     # or like(t.product_symbol, ^"%#{search_term}%")
    #     # or like(t.venue_product_symbol, ^"%#{search_term}%")
    #   )
    # else
    #   query
    # end

    query
  end
end
