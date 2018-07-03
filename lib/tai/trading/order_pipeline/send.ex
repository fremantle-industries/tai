defmodule Tai.Trading.OrderPipeline.Send do
  require Logger

  def call(%Tai.Trading.Order{side: :buy, type: :limit} = order) do
    Task.start_link(fn ->
      order
      |> Tai.Exchanges.Account.buy_limit()
      |> parse_order_response(order)
    end)
  end

  def call(%Tai.Trading.Order{side: :sell, type: :limit} = order) do
    Task.start_link(fn ->
      order
      |> Tai.Exchanges.Account.sell_limit()
      |> parse_order_response(order)
    end)
  end

  def call(%Tai.Trading.Order{} = order) do
    Logger.warn(
      "order error - client_id: #{order.client_id}, cannot send unhandled order type '#{
        order.side
      } #{order.type}'"
    )
  end

  defp parse_order_response(
         {:ok, %Tai.Trading.OrderResponse{status: :expired}},
         %Tai.Trading.Order{client_id: client_id}
       ) do
    {:ok, [old_order, updated_order]} =
      Tai.Trading.OrderStore.find_by_and_update(
        [client_id: client_id],
        status: Tai.Trading.OrderStatus.expired()
      )

    Tai.Trading.Order.updated_callback(old_order, updated_order)
  end

  defp parse_order_response(
         {:ok, %Tai.Trading.OrderResponse{status: :filled, executed_size: executed_size}},
         %Tai.Trading.Order{client_id: client_id}
       ) do
    Logger.info(fn -> "order filled - client_id: #{client_id}" end)

    {:ok, [old_order, updated_order]} =
      Tai.Trading.OrderStore.find_by_and_update(
        [client_id: client_id],
        status: Tai.Trading.OrderStatus.filled(),
        executed_size: Decimal.new(executed_size)
      )

    Tai.Trading.Order.updated_callback(old_order, updated_order)
  end

  defp parse_order_response(
         {:ok, %Tai.Trading.OrderResponse{status: :pending, id: server_id}},
         %Tai.Trading.Order{client_id: client_id}
       ) do
    Logger.info(fn -> "order pending - client_id: #{client_id}" end)

    {:ok, [old_order, updated_order]} =
      Tai.Trading.OrderStore.find_by_and_update(
        [client_id: client_id],
        status: Tai.Trading.OrderStatus.pending(),
        server_id: server_id
      )

    Tai.Trading.Order.updated_callback(old_order, updated_order)
  end

  defp parse_order_response({:error, reason}, %Tai.Trading.Order{client_id: client_id}) do
    Logger.warn(fn ->
      "order error - client_id: #{client_id}, '#{inspect(reason)}'"
    end)

    {:ok, [old_order, updated_order]} =
      Tai.Trading.OrderStore.find_by_and_update(
        [client_id: client_id],
        status: Tai.Trading.OrderStatus.error(),
        error_reason: reason
      )

    Tai.Trading.Order.updated_callback(old_order, updated_order)
  end
end
