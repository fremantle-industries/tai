defmodule Tai.Commander.StartAdvisors do
  @type instance :: Tai.Advisors.Instance.t()
  @type store_id_opt :: {:store_id, atom}
  @type where_opt :: {:where, list}
  @type opt :: store_id_opt | where_opt

  @default_filters []
  @default_store_id Tai.Advisors.SpecStore.default_store_id()

  @spec execute([opt]) :: {stopped :: non_neg_integer, already_stopped :: non_neg_integer}
  def execute(options) do
    store_id = Keyword.get(options, :store_id, @default_store_id)
    filters = Keyword.get(options, :where, @default_filters)

    filters
    |> Tai.Advisors.Instances.where(store_id)
    |> Tai.Advisors.Instances.start()
  end
end
