defmodule Tai.Boot do
  @moduledoc """
  Manage subscriptions to the tai application boot process
  """

  @spec subscribe_products(atom) :: :ok
  def subscribe_products(exchange_id) do
    Tai.PubSub.subscribe({exchange_id, :products})
  end

  @spec unsubscribe_products(atom) :: :ok
  def unsubscribe_products(exchange_id) do
    Tai.PubSub.unsubscribe({exchange_id, :products})
  end

  @spec fetched_products(atom) :: :ok
  def fetched_products(exchange_id) do
    Tai.PubSub.broadcast(
      {exchange_id, :products},
      {:fetched_products, :ok, exchange_id}
    )
  end

  @spec subscribe_fees(atom, atom) :: :ok
  def subscribe_fees(exchange_id, account_id) do
    Tai.PubSub.subscribe({exchange_id, account_id, :fees})
  end

  @spec unsubscribe_fees(atom, atom) :: :ok
  def unsubscribe_fees(exchange_id, account_id) do
    Tai.PubSub.unsubscribe({exchange_id, account_id, :fees})
  end

  @spec hydrated_fees(atom, atom) :: :ok
  def hydrated_fees(exchange_id, account_id) do
    Tai.PubSub.broadcast(
      {exchange_id, account_id, :fees},
      {:hydrated_fees, :ok, exchange_id, account_id}
    )
  end
end
