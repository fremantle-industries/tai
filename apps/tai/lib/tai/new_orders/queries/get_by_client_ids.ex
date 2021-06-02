defmodule Tai.NewOrders.Queries.GetByClientIdsQuery do
  require Ecto.Query
  import Ecto.Query
  alias Tai.NewOrders.Order

  @spec call([Order.client_id]) :: Ecto.Query.t()
  def call(client_ids) do
    (o in Order)
    |> from(where: o.client_id in ^client_ids)
  end
end
