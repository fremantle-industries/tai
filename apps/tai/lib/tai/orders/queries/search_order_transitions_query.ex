defmodule Tai.Orders.Queries.SearchOrderTransitionsQuery do
  require Ecto.Query
  import Ecto.Query

  @type order_client_id :: Tai.Orders.Order.client_id()
  @type search_term :: String.t() | nil

  @spec call(order_client_id, search_term) :: Ecto.Query.t()
  def call(order_client_id, _search_term) do
    from(
      t in Tai.Orders.OrderTransition,
      where: t.order_client_id == ^order_client_id,
      order_by: [asc: :inserted_at]
    )
  end
end
