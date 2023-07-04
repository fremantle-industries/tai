defmodule Tai.Fleets.Queries.Search do
  alias Tai.Fleets

  @type store_id_opt :: {:store_id, atom}
  @type where_opt :: {:where, list}
  @type order_opt :: {:order, list}
  @type opt :: store_id_opt | where_opt | order_opt
  @type result :: [Tai.Fleets.FleetConfig.t()]

  @default_filters []
  @default_order [:id]
  @default_store_id Tai.Fleets.FleetConfigStore.default_store_id()

  @spec call([opt]) :: result
  def call(options) do
    store_id = Keyword.get(options, :store_id, @default_store_id)
    filters = Keyword.get(options, :where, @default_filters)
    order_by = Keyword.get(options, :order, @default_order)

    store_id
    |> Fleets.FleetConfigStore.all()
    |> Enumerati.filter(filters)
    |> Enumerati.order(order_by)
  end
end
