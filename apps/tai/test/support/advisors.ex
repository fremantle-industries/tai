defmodule Support.Advisors do
  def insert_spec(attrs, store_id) when is_map(attrs) do
    required_attrs = build_attrs(attrs)

    Tai.Advisors.Spec
    |> struct(required_attrs)
    |> Tai.Advisors.Store.upsert(store_id)
  end

  defp build_attrs(attrs) do
    mod = Map.get(attrs, :mod, Support.NoopAdvisor)
    products = Map.get(attrs, :products, [])

    attrs |> Map.put(:mod, mod) |> Map.put(:products, products)
  end
end
