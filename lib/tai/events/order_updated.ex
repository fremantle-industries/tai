defmodule Tai.Events.OrderUpdated do
  @type client_id :: Tai.Trading.Order.client_id()
  @type side :: Tai.Trading.Order.side()
  @type type :: Tai.Trading.Order.type()
  @type time_in_force :: Tai.Trading.Order.time_in_force()
  @type status :: Tai.Trading.Order.status()
  @type product_type :: Tai.Venues.Product.type()
  @type t :: %Tai.Events.OrderUpdated{
          client_id: client_id,
          venue_id: atom,
          account_id: atom,
          venue_order_id: String.t() | nil,
          product_symbol: atom,
          product_type: product_type,
          side: side,
          type: type,
          time_in_force: time_in_force,
          status: status,
          price: Decimal.t(),
          avg_price: Decimal.t(),
          qty: Decimal.t(),
          leaves_qty: Decimal.t(),
          cumulative_qty: Decimal.t(),
          enqueued_at: DateTime.t(),
          last_received_at: DateTime.t() | nil,
          last_venue_timestamp: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @enforce_keys [
    :client_id,
    :venue_id,
    :account_id,
    :product_symbol,
    :product_type,
    :side,
    :type,
    :time_in_force,
    :status,
    :price,
    :avg_price,
    :qty,
    :leaves_qty,
    :cumulative_qty,
    :enqueued_at
  ]
  defstruct [
    :client_id,
    :venue_id,
    :account_id,
    :product_symbol,
    :product_type,
    :venue_order_id,
    :side,
    :type,
    :time_in_force,
    :status,
    :error_reason,
    :price,
    :avg_price,
    :qty,
    :leaves_qty,
    :cumulative_qty,
    :enqueued_at,
    :last_received_at,
    :last_venue_timestamp,
    :updated_at
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
    |> Map.put(:error_reason, event.error_reason |> inspect)
    |> Map.put(:avg_price, event.avg_price |> Decimal.to_string(:normal))
    |> Map.put(:price, event.price |> Decimal.to_string(:normal))
    |> Map.put(:qty, event.qty |> Decimal.to_string(:normal))
    |> Map.put(:leaves_qty, event.leaves_qty |> Decimal.to_string(:normal))
    |> Map.put(:cumulative_qty, event.cumulative_qty |> Decimal.to_string(:normal))
    |> Map.put(
      :enqueued_at,
      event.enqueued_at && event.enqueued_at |> DateTime.to_iso8601()
    )
    |> Map.put(
      :last_received_at,
      event.last_received_at && event.last_received_at |> DateTime.to_iso8601()
    )
    |> Map.put(
      :last_venue_timestamp,
      event.last_venue_timestamp && event.last_venue_timestamp |> DateTime.to_iso8601()
    )
    |> Map.put(
      :updated_at,
      event.updated_at && event.updated_at |> DateTime.to_iso8601()
    )
  end
end
