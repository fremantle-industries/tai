defmodule Tai.Venue do
  @type config :: Tai.Config.t()
  @type adapter :: Tai.Venues.Adapter.t()
  @type product :: Tai.Venues.Product.t()
  @type asset_balance :: Tai.Venues.AssetBalance.t()
  @type order :: Tai.Trading.Order.t()
  @type order_response :: Tai.Trading.OrderResponse.t()
  @type shared_error_reason :: :timeout | Tai.CredentialError.t()
  @type create_order_error_reason ::
          :not_implemented
          | shared_error_reason
          | Tai.Trading.InsufficientBalanceError.t()

  @adapters Tai.Venues.Config.parse_adapters()
            |> Enum.reduce(%{}, fn {_, adapter}, acc ->
              Map.put(acc, adapter.id, adapter)
            end)

  @spec products(adapter :: adapter) :: {:ok, [product]}
  def products(%Tai.Venues.Adapter{adapter: adapter, id: exchange_id}) do
    adapter.products(exchange_id)
  end

  @spec asset_balances(adapter :: adapter, account_id :: atom) :: {:ok, [asset_balance]}
  def asset_balances(
        %Tai.Venues.Adapter{adapter: adapter, id: exchange_id, accounts: accounts},
        account_id
      ) do
    {:ok, credentials} = Map.fetch(accounts, account_id)
    adapter.asset_balances(exchange_id, account_id, credentials)
  end

  @spec maker_taker_fees(adapter :: adapter, account_id :: atom) ::
          {:ok, {maker :: Decimal.t(), taker :: Decimal.t()}}
  def maker_taker_fees(
        %Tai.Venues.Adapter{adapter: adapter, id: exchange_id, accounts: accounts},
        account_id
      ) do
    {:ok, credentials} = Map.fetch(accounts, account_id)
    adapter.maker_taker_fees(exchange_id, account_id, credentials)
  end

  @spec create_order(order) :: {:ok, order_response} | {:error, create_order_error_reason}
  def create_order(%Tai.Trading.Order{} = order, adapters \\ @adapters) do
    venue_adapter = adapters |> Map.fetch!(order.exchange_id)
    credentials = Map.fetch!(venue_adapter.accounts, order.account_id)
    venue_adapter.adapter.create_order(order, credentials)
  end

  @spec cancel_order(order) :: term
  def cancel_order(%Tai.Trading.Order{} = order, adapters \\ @adapters) do
    venue_adapter = adapters |> Map.fetch!(order.exchange_id)
    credentials = Map.fetch!(venue_adapter.accounts, order.account_id)
    venue_adapter.adapter.cancel_order(order.venue_order_id, credentials)
  end
end
