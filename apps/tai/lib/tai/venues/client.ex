defmodule Tai.Venues.Client do
  alias Tai.Venues.Adapter
  alias Tai.Trading.{Order, OrderResponses}

  @type venue :: Tai.Venue.t()
  @type account_id :: Tai.Venue.account_id()
  @type order :: Order.t()
  @type shared_error_reason :: Adapter.shared_error_reason()

  @type product :: Tai.Venues.Product.t()

  @spec products(venue) :: {:ok, [product]} | {:error, shared_error_reason}
  def products(venue), do: venue.adapter.products(venue.id)

  @type asset_balance :: Tai.Venues.AssetBalance.t()

  @spec asset_balances(venue, account_id) ::
          {:ok, [asset_balance]} | {:error, shared_error_reason}
  def asset_balances(venue, account_id) do
    {:ok, credentials} = Map.fetch(venue.accounts, account_id)
    venue.adapter.asset_balances(venue.id, account_id, credentials)
  end

  @type position :: Tai.Trading.Position.t()
  @type positions_error_reason :: Adapter.positions_error_reason()

  @spec positions(venue, account_id) :: {:ok, [position]} | {:error, positions_error_reason}
  def positions(venue, account_id) do
    {:ok, credentials} = Map.fetch(venue.accounts, account_id)
    venue.adapter.positions(venue.id, account_id, credentials)
  end

  @spec maker_taker_fees(venue, account_id) ::
          {:ok, {maker :: Decimal.t(), taker :: Decimal.t()} | nil}
          | {:error, shared_error_reason}
  def maker_taker_fees(venue, account_id) do
    {:ok, credentials} = Map.fetch(venue.accounts, account_id)
    venue.adapter.maker_taker_fees(venue.id, account_id, credentials)
  end

  @type create_response :: OrderResponses.Create.t() | OrderResponses.CreateAccepted.t()
  @type create_order_error_reason :: Adapter.create_order_error_reason()

  @spec create_order(order) :: {:ok, create_response} | {:error, create_order_error_reason}
  def create_order(%Order{} = order, venues \\ Tai.Venues.Config.parse()) do
    {venue, credentials} = find_venue_and_credentials(order, venues)
    venue.adapter.create_order(order, credentials)
  end

  @type amend_attrs :: Tai.Trading.Orders.Amend.attrs()
  @type amend_response :: OrderResponses.Amend.t()
  @type amend_order_error_reason :: Adapter.amend_order_error_reason()

  @spec amend_order(order, amend_attrs) ::
          {:ok, amend_response} | {:error, amend_order_error_reason}
  def amend_order(%Order{} = order, attrs, venues \\ Tai.Venues.Config.parse()) do
    {venue, credentials} = find_venue_and_credentials(order, venues)
    venue.adapter.amend_order(order, attrs, credentials)
  end

  @type amend_bulk_attrs :: Tai.Trading.Orders.AmendBulk.attrs()
  @type amend_bulk_response :: OrderResponses.AmendBulk.t()
  @type amend_bulk_order_error_reason :: Adapter.amend_order_error_reason()

  @spec amend_bulk_orders([{order, amend_bulk_attrs}]) ::
          {:ok, amend_bulk_response} | {:error, amend_bulk_order_error_reason}
  def amend_bulk_orders(
        [{%Order{} = order, _} | _] = orders_and_attributes,
        venues \\ Tai.Venues.Config.parse()
      ) do
    {venue, credentials} = find_venue_and_credentials(order, venues)
    venue.adapter.amend_bulk_orders(orders_and_attributes, credentials)
  end

  @type cancel_response :: OrderResponses.Cancel.t() | OrderResponses.CancelAccepted.t()
  @type cancel_order_error_reason :: Adapter.cancel_order_error_reason()

  @spec cancel_order(order) :: {:ok, cancel_response} | {:error, cancel_order_error_reason}
  def cancel_order(%Order{} = order, venues \\ Tai.Venues.Config.parse()) do
    {venue, credentials} = find_venue_and_credentials(order, venues)
    venue.adapter.cancel_order(order, credentials)
  end

  defp find_venue_and_credentials(order, venues) do
    venue = venues |> Map.fetch!(order.venue_id)
    credentials = Map.fetch!(venue.accounts, order.account_id)

    {venue, credentials}
  end
end
