defmodule Tai.Trading.OrderPipeline.Send do
  alias Tai.Trading.{OrderResponse, Order, OrderPipeline}

  def execute_step(%Order{status: :enqueued} = o) do
    if Tai.Settings.send_orders?() do
      o
      |> send_request
      |> parse_response(o)
      |> execute_callback
    else
      o.client_id
      |> skip!
      |> execute_callback
    end
  end

  defp send_request(%Order{} = o) do
    Tai.Exchanges.Account.create_order(o)
  end

  defp parse_response({:ok, %OrderResponse{status: :filled} = r}, %Order{} = o) do
    fill!(o.client_id, r.executed_size)
  end

  defp parse_response({:ok, %OrderResponse{status: :expired}}, %Order{client_id: cid}) do
    expire!(cid)
  end

  defp parse_response({:ok, %OrderResponse{status: :pending, id: sid}}, %Order{client_id: cid}) do
    pend!(cid, sid)
  end

  defp parse_response({:error, reason}, %Order{client_id: cid}) do
    error!(cid, reason)
  end

  defp fill!(cid, executed_size) do
    cid
    |> find_by_and_update(
      status: :filled,
      executed_size: Decimal.new(executed_size)
    )
  end

  defp expire!(cid) do
    cid
    |> find_by_and_update(status: :expired)
  end

  defp pend!(cid, server_id) do
    cid
    |> find_by_and_update(
      status: :pending,
      server_id: server_id
    )
  end

  defp error!(cid, reason) do
    cid
    |> find_by_and_update(
      status: :error,
      error_reason: reason
    )
  end

  defp skip!(cid) do
    cid
    |> find_by_and_update(status: :skip)
  end

  defp find_by_and_update(client_id, attrs) do
    {:ok, {old_order, updated_order}} =
      Tai.Trading.OrderStore.find_by_and_update(
        [client_id: client_id],
        attrs
      )

    OrderPipeline.Events.info(updated_order)

    {old_order, updated_order}
  end

  defp execute_callback({old_order, updated_order}) do
    Tai.Trading.Order.execute_update_callback(old_order, updated_order)
  end
end
