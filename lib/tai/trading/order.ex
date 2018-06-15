defmodule Tai.Trading.Order do
  @type t :: Tai.Trading.Order

  @enforce_keys [
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
  defstruct executed_size: 0,
            client_id: nil,
            created_at: nil,
            enqueued_at: nil,
            error_reason: nil,
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
  Execute the callback function in a new task
  """
  def updated_callback(previous_order, %Tai.Trading.Order{} = updated_order) do
    if updated_order.order_updated_callback do
      {:ok, _pid} =
        Task.start_link(fn ->
          updated_order.order_updated_callback.(previous_order, updated_order)
        end)
    end
  end
end
