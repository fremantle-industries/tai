defmodule Tai.Trading.Order do
  alias Tai.Trading.Order

  @type client_id :: String.t()
  @type venue_order_id :: String.t()
  @type side :: :buy | :sell
  @type time_in_force :: :gtc | :fok | :ioc
  @type type :: :limit
  @type status ::
          :enqueued
          | :skip
          | :pending
          | :open
          | :pending_amend
          | :expired
          | :filled
          | :canceling
          | :canceled
          | :rejected
          | :error
  @type t :: %Order{
          client_id: client_id,
          venue_order_id: venue_order_id | nil,
          venue_created_at: DateTime.t() | nil,
          venue_updated_at: DateTime.t() | nil,
          exchange_id: atom,
          account_id: atom,
          enqueued_at: DateTime.t(),
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
          post_only: boolean
        }

  @enforce_keys [
    :exchange_id,
    :account_id,
    :client_id,
    :enqueued_at,
    :price,
    :avg_price,
    :side,
    :qty,
    :leaves_qty,
    :cumulative_qty,
    :status,
    :symbol,
    :time_in_force,
    :type,
    :post_only
  ]
  defstruct [
    :client_id,
    :venue_created_at,
    :venue_updated_at,
    :enqueued_at,
    :error_reason,
    :exchange_id,
    :account_id,
    :price,
    :avg_price,
    :venue_order_id,
    :side,
    :qty,
    :leaves_qty,
    :cumulative_qty,
    :status,
    :symbol,
    :time_in_force,
    :type,
    :post_only,
    :order_updated_callback
  ]
end
