defmodule Tai.Venue do
  alias __MODULE__

  @type id :: atom
  @type adapter :: Tai.Venues.Adapter.t()
  @type channel :: atom
  @type account_id :: atom
  @type account :: map
  @type accounts :: %{account_id => account}
  @type t :: %Venue{
          id: id,
          adapter: adapter,
          channels: [channel],
          products: String.t() | function,
          accounts: accounts,
          quote_depth: pos_integer,
          timeout: non_neg_integer,
          opts: map
        }

  @enforce_keys ~w(
    id
    adapter
    channels
    products
    accounts
    quote_depth
    timeout
    opts
  )a
  defstruct ~w(
    id
    adapter
    channels
    products
    accounts
    quote_depth
    timeout
    opts
  )a

  alias Tai.Venues.Adapter
  alias Tai.Trading.{Order, OrderResponses}

  @type order :: Order.t()
  @type shared_error_reason :: Adapter.shared_error_reason()

  @type product :: Tai.Venues.Product.t()

  @deprecated "Use Tai.Venues.Client.products/1 instead."
  @spec products(t) :: {:ok, [product]} | {:error, shared_error_reason}
  def products(venue_adapter) do
    Tai.Venues.Client.products(venue_adapter)
  end

  @type asset_balance :: Tai.Venues.AssetBalance.t()

  @deprecated "Use Tai.Venues.Client.asset_balances/2 instead."
  @spec asset_balances(t, account_id) ::
          {:ok, [asset_balance]} | {:error, shared_error_reason}
  def asset_balances(venue_adapter, account_id) do
    Tai.Venues.Client.asset_balances(venue_adapter, account_id)
  end

  @type position :: Tai.Trading.Position.t()
  @type positions_error_reason :: Adapter.positions_error_reason()

  @deprecated "Use Tai.Venues.Client.positions/2 instead."
  @spec positions(t, account_id) :: {:ok, [position]} | {:error, positions_error_reason}
  def positions(venue_adapter, account_id) do
    Tai.Venues.Client.positions(venue_adapter, account_id)
  end

  @deprecated "Use Tai.Venues.Client.maker_taker_fees/2 instead."
  @spec maker_taker_fees(t, account_id) ::
          {:ok, {maker :: Decimal.t(), taker :: Decimal.t()} | nil}
          | {:error, shared_error_reason}
  def maker_taker_fees(venue_adapter, account_id) do
    Tai.Venues.Client.maker_taker_fees(venue_adapter, account_id)
  end

  @type create_response :: OrderResponses.Create.t() | OrderResponses.CreateAccepted.t()
  @type create_order_error_reason :: Adapter.create_order_error_reason()

  @deprecated "Use Tai.Venues.Client.create_order/2 instead."
  @spec create_order(order) :: {:ok, create_response} | {:error, create_order_error_reason}
  def create_order(%Order{} = order, adapters \\ Tai.Venues.Config.parse()) do
    Tai.Venues.Client.create_order(order, adapters)
  end

  @type amend_attrs :: Tai.Trading.Orders.Amend.attrs()
  @type amend_response :: OrderResponses.Amend.t()
  @type amend_order_error_reason :: Adapter.amend_order_error_reason()

  @deprecated "Use Tai.Venues.Client.amend_order/3 instead."
  @spec amend_order(order, amend_attrs) ::
          {:ok, amend_response} | {:error, amend_order_error_reason}
  def amend_order(%Order{} = order, attrs, adapters \\ Tai.Venues.Config.parse()) do
    Tai.Venues.Client.amend_order(order, attrs, adapters)
  end

  @type amend_bulk_attrs :: Tai.Trading.Orders.AmendBulk.attrs()
  @type amend_bulk_response :: OrderResponses.AmendBulk.t()
  @type amend_bulk_order_error_reason :: Adapter.amend_order_error_reason()

  @deprecated "Use Tai.Venues.Client.amend_bulk_orders/2 instead."
  @spec amend_bulk_orders([{order, amend_bulk_attrs}]) ::
          {:ok, amend_bulk_response} | {:error, amend_bulk_order_error_reason}
  def amend_bulk_orders(
        [{%Order{} = _order, _} | _] = orders_and_attributes,
        adapters \\ Tai.Venues.Config.parse()
      ) do
    Tai.Venues.Client.amend_bulk_orders(orders_and_attributes, adapters)
  end

  @type cancel_response :: OrderResponses.Cancel.t() | OrderResponses.CancelAccepted.t()
  @type cancel_order_error_reason :: Adapter.cancel_order_error_reason()

  @deprecated "Use Tai.Venues.Client.cancel_order/2 instead."
  @spec cancel_order(order) :: {:ok, cancel_response} | {:error, cancel_order_error_reason}
  def cancel_order(%Order{} = order, adapters \\ Tai.Venues.Config.parse()) do
    Tai.Venues.Client.cancel_order(order, adapters)
  end
end
