defmodule Tai.Trading.Orders do
  alias Tai.Trading.{
    Order,
    OrderSubmissions,
    OrderWorker
  }

  @type submission :: OrderSubmissions.Factory.submission()
  @type order :: Order.t()
  @type create_response :: OrderWorker.create_response()
  @type cancel_response :: OrderWorker.cancel_response()
  @type amend_attrs :: OrderWorker.amend_attrs()
  @type amend_response :: OrderWorker.amend_response()
  @type amend_bulk_response :: OrderWorker.amend_bulk_response()

  @timeout 5_000

  @spec create(submission) :: create_response
  def create(submission) do
    :poolboy.transaction(
      :order_worker,
      & OrderWorker.create(&1, submission),
      @timeout
    )
  end

  @spec amend(order, amend_attrs) :: amend_response
  @spec amend(order, amend_attrs, module) :: amend_response
  def amend(order, attrs, provider \\ OrderWorker.Provider) do
    :poolboy.transaction(
      :order_worker,
      & OrderWorker.amend(&1, order, attrs, provider),
      @timeout
    )
  end

  @spec amend_bulk([{order, amend_attrs}]) :: amend_bulk_response
  @spec amend_bulk([{order, amend_attrs}], module) :: amend_bulk_response
  def amend_bulk(amend_set, provider \\ OrderWorker.Provider) do
    :poolboy.transaction(
      :order_worker,
      & OrderWorker.amend_bulk(&1, amend_set, provider),
      @timeout
    )
  end

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
