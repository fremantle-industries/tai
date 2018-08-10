defmodule Tai.Trading.OrderPipeline.Send do
  require Logger

  alias Tai.Trading.{OrderResponse, Order}

  def execute_step(%Order{status: :enqueued} = o) do
    if Tai.Settings.send_orders?() do
      o
      |> send_request
      |> parse_response(o)
      |> execute_callback
    else
      o
      |> skip_order!
      |> execute_callback
    end
  end

  defp send_request(%Order{side: :buy, type: :limit} = o) do
    o |> Tai.Exchanges.Account.buy_limit()
  end

  defp send_request(%Order{side: :sell, type: :limit} = o) do
    o |> Tai.Exchanges.Account.sell_limit()
  end

  defp parse_response({:ok, %OrderResponse{status: :filled} = o}, %Order{client_id: cid}) do
    fill_order!(cid, o.executed_size)
  end

  defp parse_response({:ok, %OrderResponse{status: :expired}}, %Order{client_id: cid}) do
    expire_order!(cid)
  end

  defp parse_response({:ok, %OrderResponse{status: :pending, id: sid}}, %Order{client_id: cid}) do
    pend_order!(cid, sid)
  end

  defp parse_response({:error, reason}, %Order{client_id: cid}) do
    order_error!(cid, reason)
  end

  defp fill_order!(client_id, executed_size) do
    Logger.info(fn -> "order filled - client_id: #{client_id}" end)

    client_id
    |> find_by_and_update(
      status: Tai.Trading.OrderStatus.filled(),
      executed_size: Decimal.new(executed_size)
    )
    |> to_next_step
  end

  defp expire_order!(client_id) do
    client_id
    |> find_by_and_update(status: Tai.Trading.OrderStatus.expired())
    |> to_next_step
  end

  defp pend_order!(client_id, server_id) do
    Logger.info(fn -> "order pending - client_id: #{client_id}" end)

    client_id
    |> find_by_and_update(
      status: Tai.Trading.OrderStatus.pending(),
      server_id: server_id
    )
    |> to_next_step
  end

  defp order_error!(client_id, reason) do
    Logger.warn(fn ->
      "order error - client_id: #{client_id}, '#{inspect(reason)}'"
    end)

    client_id
    |> find_by_and_update(
      status: Tai.Trading.OrderStatus.error(),
      error_reason: reason
    )
    |> to_next_step
  end

  defp skip_order!(o) do
    o.client_id
    |> find_by_and_update(status: Tai.Trading.OrderStatus.skip())
    |> to_next_step
  end

  defp find_by_and_update(client_id, attrs) do
    Tai.Trading.OrderStore.find_by_and_update(
      [client_id: client_id],
      attrs
    )
  end

  defp to_next_step({:ok, [old_order, updated_order]}) do
    {old_order, updated_order}
  end

  defp execute_callback({old_order, updated_order}) do
    Tai.Trading.Order.execute_update_callback(old_order, updated_order)
  end
end
