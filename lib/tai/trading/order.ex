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
          | :expired
          | :filled
          | :canceling
          | :canceled
          | :rejected
          | :error
  @type t :: %Order{
          client_id: client_id,
          venue_order_id: venue_order_id | nil,
          exchange_id: atom,
          account_id: atom,
          enqueued_at: DateTime.t(),
          side: side,
          status: status,
          symbol: atom,
          time_in_force: time_in_force,
          type: type,
          price: Decimal.t(),
          size: Decimal.t(),
          post_only: boolean
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
    :type,
    :post_only
  ]
  defstruct executed_size: Decimal.new(0),
            client_id: nil,
            created_at: nil,
            enqueued_at: nil,
            error_reason: nil,
            exchange_id: nil,
            account_id: nil,
            price: nil,
            venue_order_id: nil,
            side: nil,
            size: nil,
            status: nil,
            symbol: nil,
            time_in_force: nil,
            type: nil,
            post_only: nil,
            order_updated_callback: nil
end
