defmodule Tai.Trading.Order do
  @enforce_keys [
    :client_id,
    :enqueued_at,
    :exchange,
    :price,
    :side,
    :size,
    :status,
    :symbol,
    :type
  ]
  defstruct [
    :client_id,
    :created_at,
    :enqueued_at,
    :exchange,
    :price,
    :server_id,
    :side,
    :size,
    :status,
    :symbol,
    :type
  ]

  alias Tai.Trading.Order

  @doc """
  Returns the buy side symbol
  """
  def buy, do: :buy

  @doc """
  Returns the sell side symbol
  """
  def sell, do: :sell

  @doc """
  Returns the limit type symbol
  """
  def limit, do: :limit

  @doc """
  Returns true for buy side orders with a limit type, returns false otherwise
  """
  def buy_limit?(%Order{side: :buy, type: :limit}), do: true
  def buy_limit?(%Order{}), do: false

  @doc """
  Returns true for sell side orders with a limit type, returns false otherwise
  """
  def sell_limit?(%Order{side: :sell, type: :limit}), do: true
  def sell_limit?(%Order{}), do: false
end
