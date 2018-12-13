defmodule Tai.Venues.Adapter do
  @type credentials :: map
  @type product :: Tai.Venues.Product.t()
  @type asset_balance :: Tai.Venues.AssetBalance.t()
  @type order :: Tai.Trading.Order.t()
  @type order_response :: Tai.Trading.OrderResponse.t()
  @type shared_error_reason :: :timeout | Tai.CredentialError.t()
  @type create_order_error_reason ::
          :not_implemented
          | shared_error_reason
          | Tai.Trading.InsufficientBalanceError.t()
  @type t :: %Tai.Venues.Adapter{
          id: :atom,
          adapter: :atom,
          products: String.t(),
          accounts: map
        }

  @callback stream_supervisor :: atom
  @callback order_book_feed :: atom
  @callback products(exchange_id :: atom) :: {:ok, [product]} | {:error, reason :: term}
  @callback asset_balances(exchange_id :: atom, account_id :: atom, credentials :: map) ::
              {:ok, [asset_balance]} | {:error, reason :: term}
  @callback maker_taker_fees(exchange_id :: atom, account_id :: atom, credentials :: map) ::
              {:ok, {maker :: Decimal.t(), taker :: Decimal.t()} | nil} | {:error, reason :: term}
  @callback create_order(order, credentials) ::
              {:ok, order_response} | {:error, create_order_error_reason}

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

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour Tai.Venues.Adapter
    end
  end
end
