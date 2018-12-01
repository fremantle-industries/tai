defmodule Tai.Events.OrderUpdated do
  @type client_id :: Tai.Trading.Order.client_id()
  @type side :: Tai.Trading.Order.side()
  @type type :: Tai.Trading.Order.type()
  @type time_in_force :: Tai.Trading.Order.time_in_force()
  @type status :: Tai.Trading.Order.status()
  @type t :: %Tai.Events.OrderUpdated{
          client_id: client_id,
          venue_id: atom,
          account_id: atom,
          product_symbol: atom,
          side: side,
          type: type,
          time_in_force: time_in_force,
          status: status,
          price: Decimal.t(),
          size: Decimal.t(),
          executed_size: Decimal.t()
        }

  @enforce_keys [
    :client_id,
    :venue_id,
    :account_id,
    :product_symbol,
    :side,
    :type,
    :time_in_force,
    :status,
    :price,
    :size,
    :executed_size
  ]
  defstruct [
    :client_id,
    :venue_id,
    :account_id,
    :product_symbol,
    :side,
    :type,
    :time_in_force,
    :status,
    :error_reason,
    :price,
    :size,
    :executed_size
  ]
end

defimpl Tai.LogEvent, for: Tai.Events.OrderUpdated do
  def to_data(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    event
    |> Map.take(keys)
    |> Map.put(:price, event.price |> Decimal.to_string(:normal))
    |> Map.put(:size, event.size |> Decimal.to_string(:normal))
    |> Map.put(:executed_size, event.executed_size |> Decimal.to_string(:normal))
  end
end
