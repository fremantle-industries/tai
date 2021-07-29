defmodule Tai.Venues.Client do
  alias Tai.Venues.Adapter
  alias Tai.Orders.{Order, Responses, Worker}

  @type venue :: Tai.Venue.t()
  @type credential_id :: Tai.Venue.credential_id()
  @type order :: Order.t()
  @type shared_error_reason :: Adapter.shared_error_reason()

  @type product :: Tai.Venues.Product.t()

  @spec products(venue) :: {:ok, [product]} | {:error, shared_error_reason}
  def products(venue), do: venue.adapter.products(venue.id)

  @type account :: Tai.Venues.Account.t()

  @spec accounts(venue, credential_id) :: {:ok, [account]} | {:error, shared_error_reason}
  def accounts(venue, credential_id) do
    {:ok, credentials} = find_credentials(venue, credential_id)
    venue.adapter.accounts(venue.id, credential_id, credentials)
  end

  @type position :: Tai.Trading.Position.t()
  @type positions_error_reason :: Adapter.positions_error_reason()

  @spec positions(venue, credential_id) :: {:ok, [position]} | {:error, positions_error_reason}
  def positions(venue, credential_id) do
    {:ok, credentials} = find_credentials(venue, credential_id)
    venue.adapter.positions(venue.id, credential_id, credentials)
  end

  @spec maker_taker_fees(venue, credential_id) ::
          {:ok, {maker :: Decimal.t(), taker :: Decimal.t()} | nil}
          | {:error, shared_error_reason}
  def maker_taker_fees(venue, credential_id) do
    {:ok, credentials} = find_credentials(venue, credential_id)
    venue.adapter.maker_taker_fees(venue.id, credential_id, credentials)
  end

  @type create_response :: Responses.CreateAccepted.t()
  @type create_order_error_reason :: Adapter.create_order_error_reason()

  @spec create_order(order) :: {:ok, create_response} | {:error, create_order_error_reason}
  def create_order(%Order{} = order) do
    venue_id = order.venue |> String.to_atom()
    credential_id = order.credential |> String.to_atom()
    {:ok, venue} = Tai.Venues.VenueStore.find(venue_id)
    {:ok, credentials} = find_credentials(venue, credential_id)
    venue.adapter.create_order(order, credentials)
  end

  @type cancel_response :: Responses.CancelAccepted.t()
  @type cancel_order_error_reason :: Adapter.cancel_order_error_reason()

  @spec cancel_order(order) :: {:ok, cancel_response} | {:error, cancel_order_error_reason}
  def cancel_order(%Order{} = order) do
    venue_id = order.venue |> String.to_atom()
    credential_id = order.credential |> String.to_atom()
    {:ok, venue} = Tai.Venues.VenueStore.find(venue_id)
    {:ok, credentials} = find_credentials(venue, credential_id)
    venue.adapter.cancel_order(order, credentials)
  end

  @type amend_attrs :: Worker.amend_attrs()
  @type amend_response :: Responses.AmendAccepted.t()
  @type amend_order_error_reason :: Adapter.amend_order_error_reason()

  @spec amend_order(order, amend_attrs) ::
          {:ok, amend_response} | {:error, amend_order_error_reason}
  def amend_order(%Order{} = order, attrs) do
    venue_id = order.venue |> String.to_atom()
    credential_id = order.credential |> String.to_atom()
    {:ok, venue} = Tai.Venues.VenueStore.find(venue_id)
    {:ok, credentials} = find_credentials(venue, credential_id)
    venue.adapter.amend_order(order, attrs, credentials)
  end

  @type amend_bulk_attrs :: Worker.amend_attrs()
  @type amend_bulk_response :: Responses.AmendBulk.t()
  @type amend_bulk_order_error_reason :: Adapter.amend_order_error_reason()

  @spec amend_bulk_orders([{order, amend_bulk_attrs}]) ::
          {:ok, amend_bulk_response} | {:error, amend_bulk_order_error_reason}
  def amend_bulk_orders([{%Order{} = order, _} | _] = amend_set) do
    venue_id = order.venue |> String.to_atom()
    credential_id = order.credential |> String.to_atom()
    {:ok, venue} = Tai.Venues.VenueStore.find(venue_id)
    {:ok, credentials} = find_credentials(venue, credential_id)
    venue.adapter.amend_bulk_orders(amend_set, credentials)
  end

  defp find_credentials(venue, credential_id) do
    venue.credentials
    |> Map.get(credential_id)
    |> case do
      nil -> {:error, :not_found}
      credentials -> {:ok, credentials}
    end
  end
end
