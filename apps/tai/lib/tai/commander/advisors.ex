defmodule Tai.Commander.Advisors do
  @type instance :: Tai.Advisors.Instance.t()
  @type store_id_opt :: {:store_id, atom}
  @type where_opt :: {:where, list}
  @type order_opt :: {:order, list}
  @type opt :: store_id_opt | where_opt | order_opt

  @default_filters []
  @default_order [:group_id, :advisor_id]
  @default_store_id Tai.Advisors.SpecStore.default_store_id()

  @spec get([opt]) :: [instance]
  def get(options) do
    store_id = Keyword.get(options, :store_id, @default_store_id)
    filters = Keyword.get(options, :where, @default_filters)
    order_by = Keyword.get(options, :order, @default_order)

    filters
    |> Tai.Advisors.Instances.where(store_id)
    |> Enumerati.order(order_by)
  end
end
