defmodule Tai.Venue do
  alias Tai.Venues.Adapter
  alias Tai.Trading.{Order, OrderResponses}

  @type adapter :: Adapter.t()
  @type account_id :: Adapter.account_id()
  @type product :: Tai.Venues.Product.t()
  @type asset_balance :: Tai.Venues.AssetBalance.t()
  @type position :: Tai.Trading.Position.t()
  @type order :: Order.t()
  @type shared_error_reason ::
          :timeout
          | :connect_timeout
          | :overloaded
          | :rate_limited
          | {:credentials, reason :: term}
          | {:nonce_not_increasing, String.t()}

  @spec products(adapter) :: {:ok, [product]}
  def products(%Adapter{adapter: adapter, id: exchange_id}), do: adapter.products(exchange_id)

  @spec asset_balances(adapter, account_id) :: {:ok, [asset_balance]}
  def asset_balances(
        %Adapter{adapter: adapter, id: exchange_id, accounts: accounts},
        account_id
      ) do
    {:ok, credentials} = Map.fetch(accounts, account_id)
    adapter.asset_balances(exchange_id, account_id, credentials)
  end

  @spec positions(adapter, account_id) ::
          {:ok, [position]} | {:error, :not_supported | shared_error_reason}
  def positions(%Adapter{adapter: adapter, id: exchange_id, accounts: accounts}, account_id) do
    {:ok, credentials} = Map.fetch(accounts, account_id)
    adapter.positions(exchange_id, account_id, credentials)
  end

  @spec maker_taker_fees(adapter :: adapter, account_id) ::
          {:ok, {maker :: Decimal.t(), taker :: Decimal.t()}}
  def maker_taker_fees(
        %Adapter{adapter: adapter, id: exchange_id, accounts: accounts},
        account_id
      ) do
    {:ok, credentials} = Map.fetch(accounts, account_id)
    adapter.maker_taker_fees(exchange_id, account_id, credentials)
  end

  @type create_response :: OrderResponses.Create.t() | OrderResponses.CreateAccepted.t()
  @type create_order_error_reason ::
          :not_implemented
          | {:insufficient_balance, reason :: term}
          | shared_error_reason

  @spec create_order(order) :: {:ok, create_response} | {:error, create_order_error_reason}
  def create_order(%Order{} = order, adapters \\ Tai.Venues.Config.parse_adapters()) do
    {venue_adapter, credentials} = find_venue_adapter_and_credentials(order, adapters)
    venue_adapter.adapter.create_order(order, credentials)
  end

  @type amend_attrs :: Tai.Trading.Orders.Amend.attrs()
  @type amend_response :: OrderResponses.Amend.t()
  @type amend_order_error_reason ::
          :not_implemented
          | shared_error_reason

  @spec amend_order(order, amend_attrs) ::
          {:ok, amend_response} | {:error, amend_order_error_reason}
  def amend_order(%Order{} = order, attrs, adapters \\ Tai.Venues.Config.parse_adapters()) do
    {venue_adapter, credentials} = find_venue_adapter_and_credentials(order, adapters)
    venue_adapter.adapter.amend_order(order, attrs, credentials)
  end

  @type cancel_response :: OrderResponses.Cancel.t() | OrderResponses.CancelAccepted.t()
  @type cancel_order_error_reason ::
          :not_implemented
          | :not_found
          | shared_error_reason

  @spec cancel_order(order) :: {:ok, cancel_response} | {:error, cancel_order_error_reason}
  def cancel_order(%Order{} = order, adapters \\ Tai.Venues.Config.parse_adapters()) do
    {venue_adapter, credentials} = find_venue_adapter_and_credentials(order, adapters)
    venue_adapter.adapter.cancel_order(order, credentials)
  end

  defp find_venue_adapter_and_credentials(order, adapters) do
    venue_adapter = adapters |> Map.fetch!(order.venue_id)
    credentials = Map.fetch!(venue_adapter.accounts, order.account_id)

    {venue_adapter, credentials}
  end
end
