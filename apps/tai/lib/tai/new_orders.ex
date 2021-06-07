defmodule Tai.NewOrders do
  alias Tai.NewOrders.{
    Order,
    OrderRepo,
    Queries,
    SubmissionFactory,
    Worker
  }

  @type submission :: SubmissionFactory.submission()
  @type client_id :: Order.client_id()
  @type order :: Order.t()
  @type create_response :: Worker.create_response()
  @type cancel_response :: Worker.cancel_response()
  @type amend_attrs :: Worker.amend_attrs()
  @type amend_response :: Worker.amend_response()
  @type amend_bulk_response :: Worker.amend_bulk_response()
  @type search_term :: String.t() | nil

  @order_worker :new_order_worker
  @timeout 5_000

  @spec create(submission) :: create_response
  def create(submission) do
    :poolboy.transaction(
      @order_worker,
      &Worker.create(&1, submission),
      @timeout
    )
  end

  @spec cancel(order) :: cancel_response
  def cancel(order) do
    :poolboy.transaction(
      @order_worker,
      &Worker.cancel(&1, order),
      @timeout
    )
  end

  @spec amend(order, amend_attrs) :: amend_response
  def amend(order, attrs) do
    :poolboy.transaction(
      @order_worker,
      & Worker.amend(&1, order, attrs),
      @timeout
    )
  end

  @spec amend_bulk([{order, amend_attrs}]) :: amend_bulk_response
  def amend_bulk(amend_set) do
    :poolboy.transaction(
      @order_worker,
      & Worker.amend_bulk(&1, amend_set),
      @timeout
    )
  end

  @default_page 1
  @default_page_size 25

  @spec search(search_term, list) :: [term]
  def search(query, opts \\ []) do
    page = (opts[:page] || @default_page) - 1
    page_size = opts[:page_size] || @default_page_size

    query
    |> Queries.SearchOrdersQuery.call()
    |> PagedQuery.call(page, page_size)
    |> OrderRepo.all()
  end

  @spec search_count(search_term) :: non_neg_integer
  def search_count(query) do
    query
    |> Queries.SearchOrdersQuery.call()
    |> OrderRepo.aggregate(:count)
  end

  @spec get_by_client_id(client_id) :: order | nil
  def get_by_client_id(client_id) do
    OrderRepo.get_by(Order, client_id: client_id)
  end

  @spec get_by_client_ids([client_id]) :: [order]
  def get_by_client_ids(client_ids) do
    client_ids
    |> Queries.GetByClientIdsQuery.call()
    |> OrderRepo.all()
  end

  @spec search_transitions(client_id, search_term, list) :: [term]
  def search_transitions(client_id, query, opts \\ []) do
    page = (opts[:page] || @default_page) - 1
    page_size = opts[:page_size] || @default_page_size

    client_id
    |> Queries.SearchOrderTransitionsQuery.call(query)
    |> PagedQuery.call(page, page_size)
    |> OrderRepo.all()
  end

  @spec search_transitions_count(client_id, search_term) :: non_neg_integer
  def search_transitions_count(client_id, query) do
    client_id
    |> Queries.SearchOrderTransitionsQuery.call(query)
    |> OrderRepo.aggregate(:count)
  end

  @spec search_failed_transitions(client_id, search_term, list) :: [term]
  def search_failed_transitions(client_id, query, opts \\ []) do
    page = (opts[:page] || @default_page) - 1
    page_size = opts[:page_size] || @default_page_size

    client_id
    |> Queries.SearchFailedOrderTransitionsQuery.call(query)
    |> PagedQuery.call(page, page_size)
    |> OrderRepo.all()
  end

  @spec search_failed_transitions_count(client_id, search_term) :: non_neg_integer
  def search_failed_transitions_count(client_id, query) do
    client_id
    |> Queries.SearchFailedOrderTransitionsQuery.call(query)
    |> OrderRepo.aggregate(:count)
  end

  @spec delete_all() :: {non_neg_integer, nil}
  def delete_all do
    OrderRepo.delete_all(Order)
  end
end
