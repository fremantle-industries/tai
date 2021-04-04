defmodule Tai.Trading.Orders do
  alias Tai.Orders.{
    Order,
    OrderSubmissions,
    Worker
  }

  @type submission :: OrderSubmissions.Factory.submission()
  @type order :: Order.t()
  @type create_response :: Worker.create_response()
  @type cancel_response :: Worker.cancel_response()
  @type amend_attrs :: Worker.amend_attrs()
  @type amend_response :: Worker.amend_response()
  @type amend_bulk_response :: Worker.amend_bulk_response()

  @deprecated "Use Tai.Orders.create/1 instead."
  @spec create(submission) :: create_response
  def create(submission) do
    Tai.Orders.create(submission)
  end

  @deprecated "Use Tai.Orders.cancel/2 instead."
  @spec cancel(order) :: cancel_response
  @spec cancel(order, module) :: cancel_response
  def cancel(order, provider \\ Worker.Provider) do
    Tai.Orders.cancel(order, provider)
  end

  @deprecated "Use Tai.Orders.amend/3 instead."
  @spec amend(order, amend_attrs) :: amend_response
  @spec amend(order, amend_attrs, module) :: amend_response
  def amend(order, attrs, provider \\ Worker.Provider) do
    Tai.Orders.amend(order, attrs, provider)
  end

  @deprecated "Use Tai.Orders.amend_bulk/2 instead."
  @spec amend_bulk([{order, amend_attrs}]) :: amend_bulk_response
  @spec amend_bulk([{order, amend_attrs}], module) :: amend_bulk_response
  def amend_bulk(amend_set, provider \\ Worker.Provider) do
    Tai.Orders.amend_bulk(amend_set, provider)
  end
end
