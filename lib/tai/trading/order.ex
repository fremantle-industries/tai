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

  def buy, do: :buy
  def sell, do: :sell
  def limit, do: :limit
end
