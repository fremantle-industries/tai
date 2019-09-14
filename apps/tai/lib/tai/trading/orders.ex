defmodule Tai.Trading.Orders do
  alias Tai.Trading.{Order, Orders, OrderSubmissions}

  @type submission :: OrderSubmissions.Factory.submission()
  @type order :: Order.t()
  @type status :: Order.status()
  @type status_was :: status
  @type status_required :: status | [status]
  @type action :: term
  @type cancel_error_reason :: {:invalid_status, status_was, status_required, action}
  @type cancel_response :: {:ok, updated :: order} | {:error, cancel_error_reason}
  @type amend_attrs :: Orders.Amend.attrs()
  @type amend_error_reason :: {:invalid_status, status_was, status_required, action}
  @type amend_response :: {:ok, updated :: order} | {:error, amend_error_reason}

  @spec create(submission) :: {:ok, order}
  defdelegate create(submission), to: Orders.Create

  @spec amend(order, amend_attrs, module) :: amend_response
  defdelegate amend(order, attrs, provider), to: Orders.Amend

  @spec amend(order, amend_attrs) :: amend_response
  defdelegate amend(order, attrs), to: Orders.Amend

  @spec cancel(order, module) :: cancel_response
  defdelegate cancel(order, provider), to: Orders.Cancel

  @spec cancel(order) :: cancel_response
  defdelegate cancel(order), to: Orders.Cancel
end
