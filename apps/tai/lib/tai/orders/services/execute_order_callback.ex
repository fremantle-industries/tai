defmodule Tai.Orders.Services.ExecuteOrderCallback do
  require Logger

  alias Tai.Orders.{
    Order,
    OrderCallbackStore,
    Transitions
  }

  @type order :: Order.t()
  @type transition :: Transitions.transition()

  @spec call(order | nil, order, transition | nil) :: :ok | {:error, :noproc}
  def call(previous, current, transition) do
    callback_result =
      current
      |> find_callback
      |> execute_callback(previous, current, transition)
      |> case do
        {:error, :noproc} = error -> error
        _ -> :ok
      end

    broadcast_order_updated(current.client_id, transition)

    callback_result
  end

  defp find_callback(order) do
    with {:ok, order_callback} <- OrderCallbackStore.find(order.client_id) do
      order_callback.callback
    else
      {:error, :not_found} ->
        fn _, current, _ ->
          Logger.warn("order callback not found for client_id: #{current.client_id}")
        end
    end
  end

  defp execute_callback(callback, previous, current, transition) when is_function(callback) do
    callback.(previous, current, transition)
  end

  defp execute_callback({dest, data}, previous, current, transition)
       when is_atom(dest) or is_pid(dest) do
    msg = {:order_updated, previous, current, transition, data}
    send_msg(dest, msg)
  end

  defp execute_callback(dest, previous, current, transition) when is_atom(dest) or is_pid(dest) do
    msg = {:order_updated, previous, current, transition}
    send_msg(dest, msg)
  end

  @topic_prefix "order_updated"
  defp broadcast_order_updated(client_id, transition) do
    topics = ["#{@topic_prefix}:*", "#{@topic_prefix}:#{client_id}"]
    msg = {:order_updated, client_id, transition}

    topics
    |> Enum.each(fn topic ->
      Phoenix.PubSub.broadcast(Tai.PubSub, topic, msg)
    end)
  end

  defp send_msg(dest, msg) do
    try do
      send(dest, msg)
    rescue
      _e in ArgumentError -> {:error, :noproc}
    end
  end
end
