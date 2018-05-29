defmodule Tai.Trading.OrderSubmission do
  @moduledoc """
  Order details before it is tracked and added to the OrderOutbox
  """

  alias Tai.Trading.{Order, OrderSubmission}

  @enforce_keys [:account_id, :symbol, :side, :price, :size, :time_in_force, :type]
  defstruct [:account_id, :symbol, :side, :price, :size, :time_in_force, :type]

  @doc """
  Return an OrderSubmission for buy limit orders
  """
  def buy_limit(account_id, symbol, price, size, time_in_force) do
    %OrderSubmission{
      account_id: account_id,
      symbol: symbol,
      side: Order.buy(),
      type: Order.limit(),
      price: price,
      size: size,
      time_in_force: time_in_force
    }
  end

  @doc """
  Return an OrderSubmission for sell limit orders
  """
  def sell_limit(account_id, symbol, price, size, time_in_force) do
    %OrderSubmission{
      account_id: account_id,
      symbol: symbol,
      side: Order.sell(),
      type: Order.limit(),
      price: price,
      size: size,
      time_in_force: time_in_force
    }
  end
end
