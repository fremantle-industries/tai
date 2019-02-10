defmodule Tai.Venues.Adapter do
  @type venue_id :: atom
  @type account_id :: atom
  @type credentials :: map
  @type product :: Tai.Venues.Product.t()
  @type asset_balance :: Tai.Venues.AssetBalance.t()
  @type position :: Tai.Trading.Position.t()
  @type order :: Tai.Trading.Order.t()
  @type create_response :: Tai.Trading.OrderResponses.Create.t()
  @type amend_response :: Tai.Trading.OrderResponses.Amend.t()
  @type cancel_response :: Tai.Trading.OrderResponses.Cancel.t()
  @type venue_order_id :: String.t()
  @type amend_attrs :: Tai.Trading.Orders.Amend.attrs()
  @type shared_error_reason ::
          :timeout | {:nonce_not_increasing, msg :: String.t()} | Tai.CredentialError.t()
  @type create_order_error_reason ::
          :not_implemented
          | shared_error_reason
          | Tai.Trading.InsufficientBalanceError.t()
  @type amend_order_error_reason ::
          :not_implemented
          | :not_found
          | shared_error_reason
  @type cancel_order_error_reason ::
          :not_implemented
          | :not_found
          | shared_error_reason
  @type t :: %Tai.Venues.Adapter{
          id: :atom,
          adapter: :atom,
          products: String.t(),
          accounts: map
        }

  @callback stream_supervisor :: atom
  @callback order_book_feed :: atom
  @callback products(venue_id) :: {:ok, [product]} | {:error, reason :: term}
  @callback asset_balances(venue_id :: atom, account_id, credentials) ::
              {:ok, [asset_balance]} | {:error, reason :: term}
  @callback positions(venue_id, account_id, credentials) ::
              {:ok, [position]} | {:error, :not_supported | shared_error_reason}
  @callback maker_taker_fees(venue_id, account_id, credentials) ::
              {:ok, {maker :: Decimal.t(), taker :: Decimal.t()} | nil} | {:error, reason :: term}
  @callback create_order(order, credentials) ::
              {:ok, create_response} | {:error, create_order_error_reason}
  @callback amend_order(venue_order_id, amend_attrs, credentials) ::
              {:ok, amend_response} | {:error, amend_order_error_reason}
  @callback cancel_order(venue_order_id, credentials) ::
              {:ok, cancel_response} | {:error, cancel_order_error_reason}

  @enforce_keys [
    :id,
    :adapter,
    :products,
    :accounts,
    :timeout
  ]
  defstruct [
    :id,
    :adapter,
    :products,
    :accounts,
    :timeout
  ]
end
