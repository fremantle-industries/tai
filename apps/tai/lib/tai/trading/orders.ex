defmodule Tai.Trading.Orders do
  alias Tai.Trading.{
    Order,
    Orders,
    OrderSubmissions,
    OrderWorker
  }

  @type submission :: OrderSubmissions.Factory.submission()
  @type order :: Order.t()
  @type create_response :: OrderWorker.create_response()
  @type amend_attrs :: Orders.Amend.attrs()
  @type amend_response :: Orders.Amend.response()
  @type amend_bulk_response :: Orders.AmendBulk.response()
  @type cancel_response :: OrderWorker.cancel_response()

  @timeout 5_000

  @spec create(submission) :: create_response
  def create(submission) do
    :poolboy.transaction(
      :order_worker,
      & OrderWorker.create(&1, submission),
      @timeout
    )
  end

  @spec amend(order, amend_attrs, module) :: amend_response
  defdelegate amend(order, attrs, provider), to: Orders.Amend

  @spec amend(order, amend_attrs) :: amend_response
  defdelegate amend(order, attrs), to: Orders.Amend

  @spec amend_bulk([{order, amend_attrs}]) :: amend_bulk_response
  defdelegate amend_bulk(amend_set), to: Orders.AmendBulk

  @spec amend_bulk([{order, amend_attrs}], module) :: amend_bulk_response
  defdelegate amend_bulk(amend_set, provider), to: Orders.AmendBulk

  @spec cancel(order) :: cancel_response
  @spec cancel(order, module) :: cancel_response
  def cancel(order, provider \\ OrderWorker.Provider) do
    :poolboy.transaction(
      :order_worker,
      & OrderWorker.cancel(&1, order, provider),
      @timeout
    )
  end
end
