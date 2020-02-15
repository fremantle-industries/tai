defmodule Support.Advisors do
  def insert_spec(attrs, store_id) when is_map(attrs) do
    required_attrs = build_attrs(attrs)

    Tai.Advisors.Spec
    |> struct(required_attrs)
    |> Tai.Advisors.SpecStore.put(store_id)
  end

  defp build_attrs(attrs) do
    mod = Map.get(attrs, :mod, Support.NoopAdvisor)
    products = Map.get(attrs, :products, [])
    restart = Map.get(attrs, :restart, :temporary)
    shutdown = Map.get(attrs, :shutdown, 5000)

    attrs
    |> Map.put(:mod, mod)
    |> Map.put(:products, products)
    |> Map.put(:restart, restart)
    |> Map.put(:shutdown, shutdown)
  end
end
