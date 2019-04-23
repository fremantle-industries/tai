defmodule Tai.Trading.Order do
  alias Tai.Trading.Order

  @type client_id :: Ecto.UUID.t()
  @type venue_order_id :: String.t()
  @type side :: :buy | :sell
  @type time_in_force :: :gtc | :fok | :ioc
  @type type :: :limit
  @type status ::
          :enqueued
          | :skip
          | :create_accepted
          | :open
          | :expired
          | :filled
          | :rejected
          | :create_error
          | :pending_amend
          | :amend_error
          | :pending_cancel
          | :cancel_accepted
          | :canceled
          | :cancel_error
  @type t :: %Order{
          client_id: client_id,
          venue_order_id: venue_order_id | nil,
          exchange_id: atom,
          account_id: atom,
          side: side,
          status: status,
          symbol: atom,
          time_in_force: time_in_force,
          type: type,
          price: Decimal.t(),
          avg_price: Decimal.t(),
          qty: Decimal.t(),
          leaves_qty: Decimal.t(),
          cumulative_qty: Decimal.t(),
          post_only: boolean,
          enqueued_at: DateTime.t(),
          last_received_at: DateTime.t() | nil,
          last_venue_timestamp: DateTime.t() | nil,
          updated_at: DateTime.t() | nil,
          order_updated_callback: fun | nil
        }

  @enforce_keys ~w(
    exchange_id
    account_id
    client_id
    enqueued_at
    price
    avg_price
    side
    qty
    leaves_qty
    cumulative_qty
    status
    symbol
    time_in_force
    type
    post_only
  )a
  defstruct ~w(
    client_id
    error_reason
    exchange_id
    account_id
    price
    avg_price
    venue_order_id
    side
    qty
    leaves_qty
    cumulative_qty
    status
    symbol
    time_in_force
    type
    post_only
    enqueued_at
    last_received_at
    last_venue_timestamp
    updated_at
    order_updated_callback
  )a
end
