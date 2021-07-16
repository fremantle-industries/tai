defmodule Tai.NewOrders do
  alias Tai.Orders.{
    Order,
    SubmissionFactory,
    Worker
  }

  @type submission :: SubmissionFactory.submission()
  @type client_id :: Order.client_id()
  @type order :: Order.t()
  @type create_result :: Worker.create_result()
  @type cancel_result :: Worker.cancel_result()
  @type amend_attrs :: Worker.amend_attrs()
  @type amend_result :: Worker.amend_result()
  @type amend_bulk_result :: Worker.amend_bulk_result()
  @type search_term :: String.t() | nil

  @deprecated "Use Tai.Orders.create/1 instead."
  @spec create(submission) :: create_result
  def create(submission) do
    Tai.Orders.create(submission)
  end

  @deprecated "Use Tai.Orders.cancel/1 instead."
  @spec cancel(order) :: cancel_result
  def cancel(order) do
    Tai.Orders.cancel(order)
  end

  @deprecated "Use Tai.Orders.amend/2 instead."
  @spec amend(order, amend_attrs) :: amend_result
  def amend(order, attrs) do
    Tai.Orders.amend(order, attrs)
  end

  @deprecated "Use Tai.Orders.amend_bulk/1 instead."
  @spec amend_bulk([{order, amend_attrs}]) :: amend_bulk_result
  def amend_bulk(amend_set) do
    Tai.Orders.amend_bulk(amend_set)
  end

  @deprecated "Use Tai.Orders.search/2 instead."
  @spec search(search_term, list) :: [term]
  def search(query, opts \\ []) do
    Tai.Orders.search(query, opts)
  end

  @deprecated "Use Tai.Orders.search_count/1 instead."
  @spec search_count(search_term) :: non_neg_integer
  def search_count(query) do
    Tai.Orders.search_count(query)
  end

  @deprecated "Use Tai.Orders.get_by_client_id/1 instead."
  @spec get_by_client_id(client_id) :: order | nil
  def get_by_client_id(client_id) do
    Tai.Orders.get_by_client_id(client_id)
  end

  @deprecated "Use Tai.Orders.get_by_client_ids/1 instead."
  @spec get_by_client_ids([client_id]) :: [order]
  def get_by_client_ids(client_ids) do
    Tai.Orders.get_by_client_ids(client_ids)
  end

  @deprecated "Use Tai.Orders.search_transitions/3 instead."
  @spec search_transitions(client_id, search_term, list) :: [term]
  def search_transitions(client_id, query, opts \\ []) do
    Tai.Orders.search_transitions(client_id, query, opts)
  end

  @deprecated "Use Tai.Orders.search_transition_count/2 instead."
  @spec search_transitions_count(client_id, search_term) :: non_neg_integer
  def search_transitions_count(client_id, query) do
    Tai.Orders.search_transitions_count(client_id, query)
  end

  @deprecated "Use Tai.Orders.search_failed_transitions/3 instead."
  @spec search_failed_transitions(client_id, search_term, list) :: [term]
  def search_failed_transitions(client_id, query, opts \\ []) do
    Tai.Orders.search_failed_transitions(client_id, query, opts)
  end

  @deprecated "Use Tai.Orders.search_failed_transitions_count/2 instead."
  @spec search_failed_transitions_count(client_id, search_term) :: non_neg_integer
  def search_failed_transitions_count(client_id, query) do
    Tai.Orders.search_failed_transitions_count(client_id, query)
  end

  @deprecated "Use Tai.Orders.delete_all/0 instead."
  @spec delete_all() :: {non_neg_integer, nil}
  def delete_all do
    Tai.Orders.delete_all()
  end
end
