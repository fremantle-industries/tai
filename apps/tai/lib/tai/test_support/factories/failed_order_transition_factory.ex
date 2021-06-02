defmodule Tai.TestSupport.Factories.FailedOrderTransitionFactory do
  alias Tai.NewOrders.{OrderRepo, FailedOrderTransition}

  def create_failed_order_transition(order_client_id, error, type) do
    %FailedOrderTransition{}
    |> FailedOrderTransition.changeset(%{
      order_client_id: order_client_id,
      error: error,
      type: type
    })
    |> OrderRepo.insert()
  end
end
