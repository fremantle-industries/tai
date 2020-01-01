defmodule Tai.Venues.Client do
  alias Tai.Venues.Adapter
  alias Tai.Trading.{Order, OrderResponses}

  @type adapter :: Adapter.t()
  @type account_id :: Adapter.account_id()
  @type order :: Order.t()
  @type shared_error_reason :: Adapter.shared_error_reason()

  @type product :: Tai.Venues.Product.t()

  @spec products(adapter) :: {:ok, [product]} | {:error, shared_error_reason}
  def products(venue_adapter), do: venue_adapter.adapter.products(venue_adapter.id)

  @type asset_balance :: Tai.Venues.AssetBalance.t()

  @spec asset_balances(adapter, account_id) ::
          {:ok, [asset_balance]} | {:error, shared_error_reason}
  def asset_balances(venue_adapter, account_id) do
    {:ok, credentials} = Map.fetch(venue_adapter.accounts, account_id)
    venue_adapter.adapter.asset_balances(venue_adapter.id, account_id, credentials)
  end

  @type position :: Tai.Trading.Position.t()
  @type positions_error_reason :: Adapter.positions_error_reason()

  @spec positions(adapter, account_id) :: {:ok, [position]} | {:error, positions_error_reason}
  def positions(venue_adapter, account_id) do
    {:ok, credentials} = Map.fetch(venue_adapter.accounts, account_id)
    venue_adapter.adapter.positions(venue_adapter.id, account_id, credentials)
  end

  @spec maker_taker_fees(adapter, account_id) ::
          {:ok, {maker :: Decimal.t(), taker :: Decimal.t()} | nil}
          | {:error, shared_error_reason}
  def maker_taker_fees(venue_adapter, account_id) do
    {:ok, credentials} = Map.fetch(venue_adapter.accounts, account_id)
    venue_adapter.adapter.maker_taker_fees(venue_adapter.id, account_id, credentials)
  end

  @type create_response :: OrderResponses.Create.t() | OrderResponses.CreateAccepted.t()
  @type create_order_error_reason :: Adapter.create_order_error_reason()

  @spec create_order(order) :: {:ok, create_response} | {:error, create_order_error_reason}
  def create_order(%Order{} = order, adapters \\ Tai.Venues.Config.parse_adapters()) do
    {venue_adapter, credentials} = find_venue_adapter_and_credentials(order, adapters)
    venue_adapter.adapter.create_order(order, credentials)
  end

  @type amend_attrs :: Tai.Trading.Orders.Amend.attrs()
  @type amend_response :: OrderResponses.Amend.t()
  @type amend_order_error_reason :: Adapter.amend_order_error_reason()

  @spec amend_order(order, amend_attrs) ::
          {:ok, amend_response} | {:error, amend_order_error_reason}
  def amend_order(%Order{} = order, attrs, adapters \\ Tai.Venues.Config.parse_adapters()) do
    {venue_adapter, credentials} = find_venue_adapter_and_credentials(order, adapters)
    venue_adapter.adapter.amend_order(order, attrs, credentials)
  end

  @type amend_bulk_attrs :: Tai.Trading.Orders.AmendBulk.attrs()
  @type amend_bulk_response :: OrderResponses.AmendBulk.t()
  @type amend_bulk_order_error_reason :: Adapter.amend_order_error_reason()

  @spec amend_bulk_orders([{order, amend_bulk_attrs}]) ::
          {:ok, amend_bulk_response} | {:error, amend_bulk_order_error_reason}
  def amend_bulk_orders(
        [{%Order{} = order, _} | _] = orders_and_attributes,
        adapters \\ Tai.Venues.Config.parse_adapters()
      ) do
    {venue_adapter, credentials} = find_venue_adapter_and_credentials(order, adapters)
    venue_adapter.adapter.amend_bulk_orders(orders_and_attributes, credentials)
  end

  @type cancel_response :: OrderResponses.Cancel.t() | OrderResponses.CancelAccepted.t()
  @type cancel_order_error_reason :: Adapter.cancel_order_error_reason()

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
