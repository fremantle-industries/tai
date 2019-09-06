defmodule Tai.Trading.Orders do
  alias Tai.Trading.{Order, Orders, OrderSubmissions}

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
end
