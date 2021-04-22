defmodule Tai.Orders do
  alias Tai.Orders.{
    Order,
    Submissions,
    Worker
  }

  @type submission :: Submissions.Factory.submission()
  @type order :: Order.t()
  @type create_response :: Worker.create_response()
  @type cancel_response :: Worker.cancel_response()
  @type amend_attrs :: Worker.amend_attrs()
  @type amend_response :: Worker.amend_response()
  @type amend_bulk_response :: Worker.amend_bulk_response()

  @timeout 5_000

  @spec create(submission) :: create_response
  def create(submission) do
    :poolboy.transaction(
      :order_worker,
      & Worker.create(&1, submission),
      @timeout
    )
  end

  @spec cancel(order) :: cancel_response
  @spec cancel(order, module) :: cancel_response
  def cancel(order, provider \\ Worker.Provider) do
    :poolboy.transaction(
      :order_worker,
      & Worker.cancel(&1, order, provider),
      @timeout
    )
  end

  @spec amend(order, amend_attrs) :: amend_response
  @spec amend(order, amend_attrs, module) :: amend_response
  def amend(order, attrs, provider \\ Worker.Provider) do
    :poolboy.transaction(
      :order_worker,
      & Worker.amend(&1, order, attrs, provider),
      @timeout
    )
  end

  @spec amend_bulk([{order, amend_attrs}]) :: amend_bulk_response
  @spec amend_bulk([{order, amend_attrs}], module) :: amend_bulk_response
  def amend_bulk(amend_set, provider \\ Worker.Provider) do
    :poolboy.transaction(
      :order_worker,
      & Worker.amend_bulk(&1, amend_set, provider),
      @timeout
    )
  end
end
