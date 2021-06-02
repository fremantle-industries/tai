defmodule Tai.NewOrders.Services.EnqueueOrder do
  alias Tai.NewOrders.{
    Order,
    OrderCallback,
    OrderCallbackStore,
    OrderRepo,
    Services,
    SubmissionFactory
  }

  @type submission :: term
  @type order :: Order.t()

  @spec call(submission) :: {:ok, order} | {:error, Ecto.Changeset.t() | :no_proc}
  def call(submission) do
    with {:ok, order} = order_result <- insert_order(submission),
         :ok <- store_callback(submission, order),
         :ok <- execute_callback(order) do
      order_result
    end
  end

  defp insert_order(submission) do
    submission
    |> SubmissionFactory.order_changeset()
    |> OrderRepo.insert()
  end

  defp store_callback(%_{order_updated_callback: nil}, _order), do: :ok

  defp store_callback(submission, order) do
    {:ok, _} =
      OrderCallbackStore.put(%OrderCallback{
        client_id: order.client_id,
        callback: submission.order_updated_callback
      })

    :ok
  end

  defp execute_callback(order) do
    Services.ExecuteOrderCallback.call(nil, order, nil)
  end
end
