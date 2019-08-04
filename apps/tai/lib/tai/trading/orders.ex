defmodule Tai.Trading.Orders do
  alias Tai.Trading.{Order, Orders, OrderSubmissions}
  alias Tai.Events

  @type submission :: OrderSubmissions.Factory.submission()
  @type order :: Order.t()
  @type status :: Order.status()
  @type status_was :: status
  @type status_required :: status | [status]
  @type amend_attrs :: Orders.Amend.attrs()
  @type amend_error_reason :: {:invalid_status, status_was, status_required}
  @type cancel_error_reason :: {:invalid_status, status_was, status_required}

  @spec create(submission) :: {:ok, order}
  defdelegate create(submission), to: Orders.Create

  @spec amend(order, amend_attrs) :: {:ok, updated :: order} | {:error, amend_error_reason}
  defdelegate amend(order, attrs), to: Orders.Amend

  @spec cancel(order) :: {:ok, updated :: order} | {:error, cancel_error_reason}
  defdelegate cancel(order), to: Orders.Cancel

  @spec broadcast(order) :: :ok
  def broadcast(%Order{} = order) do
    %Events.OrderUpdated{
      client_id: order.client_id,
      venue_id: order.venue_id,
      account_id: order.account_id,
      venue_order_id: order.venue_order_id,
      product_symbol: order.product_symbol,
      product_type: order.product_type,
      side: order.side,
      type: order.type,
      time_in_force: order.time_in_force,
      status: order.status,
      price: order.price,
      qty: order.qty,
      leaves_qty: order.leaves_qty,
      cumulative_qty: order.cumulative_qty,
      error_reason: order.error_reason,
      enqueued_at: order.enqueued_at,
      last_received_at: order.last_received_at,
      last_venue_timestamp: order.last_venue_timestamp,
      updated_at: order.updated_at,
      close: order.close
    }
    |> Events.info()
  end

  @spec updated!(order | nil, order) :: :ok
  def updated!(previous, %Order{} = updated) do
    broadcast(updated)

    if updated.order_updated_callback do
      updated.order_updated_callback.(previous, updated)
    else
      :ok
    end
  end
end
