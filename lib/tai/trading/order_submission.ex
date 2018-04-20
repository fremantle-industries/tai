defmodule Tai.Trading.OrderSubmission do
  @moduledoc """
  Order details before it is tracked and added to the OrderOutbox
  """

  alias Tai.Trading.{Order, OrderSubmission}

  @enforce_keys [:exchange_id, :symbol, :side, :price, :size, :type]
  defstruct [:exchange_id, :symbol, :side, :price, :size, :type]

  @doc """
  Return an OrderSubmission for buy limit orders
  """
  def buy_limit(exchange_id, symbol, price, size) do
    %OrderSubmission{
      exchange_id: exchange_id,
      symbol: symbol,
      side: Order.buy(),
      type: Order.limit(),
      price: price,
      size: size
    }
  end

  @doc """
  Return an OrderSubmission for sell limit orders
  """
  def sell_limit(exchange_id, symbol, price, size) do
    %OrderSubmission{
      exchange_id: exchange_id,
      symbol: symbol,
      side: Order.sell(),
      type: Order.limit(),
      price: price,
      size: size
    }
  end
end
