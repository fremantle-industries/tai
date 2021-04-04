defmodule Tai.Orders.Queries.FindByClientId do
  @type client_id :: Tai.Orders.Order.client_id()
  @type order :: Tai.Orders.Order.t()

  @spec execute(client_id) :: {:ok, order} | {:error, :not_found}
  def execute(client_id) do
    Tai.Orders.OrderStore.find_by_client_id(client_id)
  end
end
