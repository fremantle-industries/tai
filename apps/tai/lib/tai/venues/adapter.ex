defmodule Tai.Venues.Adapter do
  alias Tai.Trading.OrderResponses

  @type channel :: atom
  @type venue_id :: atom
  @type account_id :: atom
  @type credentials :: map
  @type product :: Tai.Venues.Product.t()
  @type asset_balance :: Tai.Venues.AssetBalance.t()
  @type position :: Tai.Trading.Position.t()
  @type order :: Tai.Trading.Order.t()
  @type create_response :: OrderResponses.Create.t() | OrderResponses.CreateAccepted.t()
  @type amend_response :: OrderResponses.Amend.t()
  @type cancel_response :: OrderResponses.Cancel.t() | OrderResponses.CancelAccepted.t()
  @type amend_attrs :: Tai.Trading.Orders.Amend.attrs()
  @type shared_error_reason ::
          :not_implemented
          | :timeout
          | :connect_timeout
          | :overloaded
          | {:credentials, reason :: term}
          | {:nonce_not_increasing, msg :: String.t()}
          | {:unhandled, reason :: term}
  @type create_order_error_reason :: shared_error_reason | :insufficient_balance
  @type amend_order_error_reason :: shared_error_reason | :not_found | :not_supported
  @type cancel_order_error_reason :: shared_error_reason | :not_found
  @type t :: %Tai.Venues.Adapter{
          id: atom,
          adapter: module,
          channels: [channel],
          products: String.t() | function,
          accounts: map,
          timeout: non_neg_integer,
          opts: map
        }

  @callback stream_supervisor :: module
  @callback order_book_feed :: module
  @callback products(venue_id) :: {:ok, [product]} | {:error, reason :: term}
  @callback asset_balances(venue_id, account_id, credentials) ::
              {:ok, [asset_balance]} | {:error, reason :: term}
  @callback positions(venue_id, account_id, credentials) ::
              {:ok, [position]} | {:error, :not_supported | shared_error_reason}
  @callback maker_taker_fees(venue_id, account_id, credentials) ::
              {:ok, {maker :: Decimal.t(), taker :: Decimal.t()} | nil} | {:error, reason :: term}
  @callback create_order(order, credentials) ::
              {:ok, create_response} | {:error, create_order_error_reason}
  @callback amend_order(order, amend_attrs, credentials) ::
              {:ok, amend_response} | {:error, amend_order_error_reason}
  @callback cancel_order(order, credentials) ::
              {:ok, cancel_response} | {:error, cancel_order_error_reason}

  @enforce_keys ~w(id adapter channels products accounts timeout opts)a
  defstruct ~w(id adapter channels products accounts timeout opts)a
end
