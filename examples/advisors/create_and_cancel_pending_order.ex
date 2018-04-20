defmodule Examples.Advisors.CreateAndCancelPendingOrder do
  use Tai.Advisor

  alias Tai.Advisor
  alias Tai.Trading.{Orders, OrderStatus, OrderSubmission}

  require Logger

  def handle_inside_quote(:gdax, symbol, inside_quote, changes, state) do
    Logger.debug(fn ->
      :io_lib.format(
        "handle_inside_quote - order_book_feed_id: ~s, symbol: ~s, quote: ~s, changes: ~s, state: ~s",
        [
          :gdax,
          symbol,
          inspect(inside_quote),
          inspect(changes),
          inspect(state)
        ]
      )
    end)

    cond do
      Orders.count() == 0 ->
        Logger.info("create buy limit order on :gdax")

        actions = %{
          orders: [OrderSubmission.buy_limit(:gdax, :btcusd, 100.1, 0.1)]
        }

        {:ok, actions}

      (pending_orders = Orders.where(status: OrderStatus.pending())) |> Enum.count() > 0 ->
        Logger.info(
          "[#{state.advisor_id |> Advisor.to_name()}] handle_inside_quote - cancel pending orders: #{
            inspect(pending_orders)
          }"
        )

        cancel_orders = pending_orders |> Enum.map(& &1.client_id)
        {:ok, %{cancel_orders: cancel_orders}}

      true ->
        :ok
    end
  end

  def handle_inside_quote(order_book_feed_id, symbol, inside_quote, changes, state) do
    Logger.debug(fn ->
      :io_lib.format(
        "handle_inside_quote - order_book_feed_id: ~s, symbol: ~s, quote: ~s, changes: ~s, state: ~s",
        [
          order_book_feed_id,
          symbol,
          inspect(inside_quote),
          inspect(changes),
          inspect(state)
        ]
      )
    end)
  end

  def handle_order_create_ok(order, _state) do
    Logger.info("order created: #{inspect(order)}")
  end

  def handle_order_create_error(reason, order, _state) do
    Logger.warn("error creating order: #{inspect(order)}, reason: #{inspect(reason)}")
  end
end
