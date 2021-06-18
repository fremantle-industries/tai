defmodule Tai.NewOrders.Queries.SearchOrderTransitionsQuery do
  require Ecto.Query
  import Ecto.Query
  alias Tai.NewOrders.{Order, OrderTransition}

  @type order_client_id :: Order.client_id
  @type search_term :: String.t() | nil

  @spec call(order_client_id, search_term) :: Ecto.Query.t()
  def call(order_client_id, _search_term) do
    from(
      t in OrderTransition,
      where: t.order_client_id == ^order_client_id,
      order_by: [asc: :inserted_at]
    )
  end
end
