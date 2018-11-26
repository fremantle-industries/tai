defmodule Tai.Trading.OrderSubmission do
  @moduledoc """
  Order details that are turned into an order and assigned a tracking client id
  """

  @type t :: %Tai.Trading.OrderSubmission{
          exchange_id: atom,
          account_id: atom,
          symbol: atom,
          side: atom,
          price: number,
          size: number,
          time_in_force: term,
          type: term
        }

  @enforce_keys [
    :exchange_id,
    :account_id,
    :symbol,
    :side,
    :price,
    :size,
    :time_in_force,
    :type
  ]
  defstruct [
    :exchange_id,
    :account_id,
    :symbol,
    :side,
    :price,
    :size,
    :time_in_force,
    :type,
    :order_updated_callback
  ]

  @doc """
  Return an OrderSubmission for buy limit orders
  """
  def buy_limit(
        exchange_id,
        account_id,
        symbol,
        price,
        size,
        time_in_force,
        order_updated_callback \\ nil
      ) do
    %Tai.Trading.OrderSubmission{
      exchange_id: exchange_id,
      account_id: account_id,
      symbol: symbol,
      side: Tai.Trading.Order.buy(),
      type: Tai.Trading.Order.limit(),
      price: price,
      size: size,
      time_in_force: time_in_force,
      order_updated_callback: order_updated_callback
    }
  end

  @doc """
  Return an OrderSubmission for sell limit orders
  """
  def sell_limit(
        exchange_id,
        account_id,
        symbol,
        price,
        size,
        time_in_force,
        order_updated_callback \\ nil
      ) do
    %Tai.Trading.OrderSubmission{
      exchange_id: exchange_id,
      account_id: account_id,
      symbol: symbol,
      side: Tai.Trading.Order.sell(),
      type: Tai.Trading.Order.limit(),
      price: price,
      size: size,
      time_in_force: time_in_force,
      order_updated_callback: order_updated_callback
    }
  end
end
