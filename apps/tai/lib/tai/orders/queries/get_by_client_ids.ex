defmodule Tai.Orders.Queries.GetByClientIdsQuery do
  require Ecto.Query
  import Ecto.Query

  @type client_id :: Tai.Orders.Order.client_id()

  @spec call([client_id]) :: Ecto.Query.t()
  def call(client_ids) do
    (o in Tai.Orders.Order)
    |> from(where: o.client_id in ^client_ids)
  end
end
