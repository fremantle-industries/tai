defmodule Tai.Trading.Order do
  alias Tai.Trading.Order

  @type client_id :: Ecto.UUID.t()
  @type venue_order_id :: String.t()
  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type account_id :: Tai.Venues.Adapter.account_id()
  @type product_symbol :: Tai.Venues.Product.symbol()
  @type product_type :: Tai.Venues.Product.type()
  @type side :: :buy | :sell
  @type time_in_force :: :gtc | :fok | :ioc
  @type type :: :limit
  @type status ::
          :enqueued
          | :skip
          | :create_accepted
          | :open
          | :partially_filled
          | :filled
          | :expired
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
          venue_id: venue_id,
          account_id: account_id,
          side: side,
          status: status,
          product_symbol: product_symbol,
          product_type: product_type,
          time_in_force: time_in_force,
          type: type,
          price: Decimal.t(),
          qty: Decimal.t(),
          leaves_qty: Decimal.t(),
          cumulative_qty: Decimal.t(),
          post_only: boolean,
          close: boolean | nil,
          enqueued_at: DateTime.t(),
          last_received_at: DateTime.t() | nil,
          last_venue_timestamp: DateTime.t() | nil,
          updated_at: DateTime.t() | nil,
          order_updated_callback: fun | nil
        }

  @enforce_keys ~w(
    venue_id
    account_id
    client_id
    enqueued_at
    price
    side
    qty
    leaves_qty
    cumulative_qty
    status
    product_symbol
    product_type
    time_in_force
    type
    post_only
  )a
  defstruct ~w(
    client_id
    error_reason
    venue_id
    account_id
    price
    venue_order_id
    side
    qty
    leaves_qty
    cumulative_qty
    status
    product_symbol
    product_type
    time_in_force
    type
    post_only
    close
    enqueued_at
    last_received_at
    last_venue_timestamp
    updated_at
    order_updated_callback
  )a
end
