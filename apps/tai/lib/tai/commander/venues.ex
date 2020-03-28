defmodule Tai.Commander.Venues do
  @type venue :: Tai.Venue.t()
  @type store_id :: Tai.Venues.VenueStore.store_id()
  @type store_id_opt :: {:store_id, store_id}
  @type where_opt :: {:where, [{atom, term}]}
  @type order_opt :: {:order, [atom]}
  @type opt :: store_id_opt | where_opt | order_opt

  @default_filters []
  @default_order [:id]
  @default_store_id Tai.Venues.VenueStore.default_store_id()

  @spec get([opt]) :: [venue]
  def get(options) do
    store_id = Keyword.get(options, :store_id, @default_store_id)
    filters = Keyword.get(options, :where, @default_filters)
    order_by = Keyword.get(options, :order, @default_order)

    store_id
    |> Tai.Venues.VenueStore.all()
    |> Enum.map(&to_instance/1)
    |> Enumerati.filter(filters)
    |> Enumerati.order(order_by)
  end

  defp to_instance(venue) do
    %Tai.Venues.Instance{
      id: venue.id,
      adapter: venue.adapter,
      channels: venue.channels,
      products: venue.products,
      accounts: venue.accounts,
      credentials: venue.credentials,
      quote_depth: venue.quote_depth,
      timeout: venue.timeout,
      start_on_boot: venue.start_on_boot,
      broadcast_change_set: venue.broadcast_change_set,
      opts: venue.opts,
      status: Tai.Venues.Status.status(venue)
    }
  end
end
