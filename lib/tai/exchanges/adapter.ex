defmodule Tai.Exchanges.Adapter do
  @type t :: %Tai.Exchanges.Adapter{
          id: :atom,
          adapter: :atom,
          products: String.t(),
          accounts: map
        }

  @type product :: Tai.Venues.Product.t()
  @type asset_balance :: Tai.Exchanges.AssetBalance.t()

  @callback stream_supervisor :: atom
  @callback order_book_feed :: atom
  @callback products(exchange_id :: atom) :: {:ok, [product]} | {:error, reason :: term}
  @callback asset_balances(exchange_id :: atom, account_id :: atom, credentials :: map) ::
              {:ok, [asset_balance]} | {:error, reason :: term}
  @callback maker_taker_fees(exchange_id :: atom, account_id :: atom, credentials :: map) ::
              {:ok, {maker :: Decimal.t(), taker :: Decimal.t()} | nil} | {:error, reason :: term}

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
      @behaviour Tai.Exchanges.Adapter
    end
  end
end
