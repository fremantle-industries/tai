defmodule Tai.Trading.Order do
  @enforce_keys [:client_id, :exchange, :symbol, :price, :size, :enqueued_at]
  defstruct [:client_id, :server_id, :exchange, :symbol, :price, :size, :enqueued_at, :created_at]
end
