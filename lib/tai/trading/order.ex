defmodule Tai.Trading.Order do
  @type t :: %Tai.Trading.Order{
          exchange_id: atom,
          account_id: atom,
          client_id: String.t(),
          enqueued_at: DateTime.t(),
          side: atom,
          status: atom,
          symbol: atom,
          time_in_force: atom,
          type: atom,
          price: Decimal.t(),
          size: Decimal.t()
        }

  @enforce_keys [
    :exchange_id,
    :account_id,
    :client_id,
    :enqueued_at,
    :price,
    :side,
    :size,
    :status,
    :symbol,
    :time_in_force,
    :type
  ]
  defstruct executed_size: Decimal.new(0),
            client_id: nil,
            created_at: nil,
            enqueued_at: nil,
            error_reason: nil,
            exchange_id: nil,
            account_id: nil,
            price: nil,
            server_id: nil,
            side: nil,
            size: nil,
            status: nil,
            symbol: nil,
            time_in_force: nil,
            type: nil,
            order_updated_callback: nil

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
  def buy_limit?(%Tai.Trading.Order{side: :buy, type: :limit}), do: true
  def buy_limit?(%Tai.Trading.Order{}), do: false

  @doc """
  Returns true for sell side orders with a limit type, returns false otherwise
  """
  def sell_limit?(%Tai.Trading.Order{side: :sell, type: :limit}), do: true
  def sell_limit?(%Tai.Trading.Order{}), do: false

  @doc """
  Execute the callback function if provided
  """
  def execute_update_callback(_prev, %Tai.Trading.Order{order_updated_callback: nil}), do: :ok

  def execute_update_callback(previous, %Tai.Trading.Order{} = updated) do
    updated.order_updated_callback.(previous, updated)
  end
end
