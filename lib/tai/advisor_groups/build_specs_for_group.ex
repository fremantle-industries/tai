defmodule Tai.AdvisorGroups.BuildSpecsForGroup do
  @type config :: Tai.Config.t()
  @type advisor_spec :: {atom, [group_id: atom, advisor_id: atom, order_books: map, store: map]}
  @type product :: Tai.Venues.Product.t()

  @spec build_specs_for_group(config, group_id :: atom, [product]) ::
          {:ok, [advisor_spec]} | {:error, map}
  def build_specs_for_group(
        %Tai.Config{} = config,
        group_id,
        products \\ Tai.Venues.ProductStore.all()
      ) do
    with {:ok, specs} <- Tai.AdvisorGroups.build_specs(config, products) do
      filtered_specs =
        Enum.filter(
          specs,
          fn {_, opts} -> Keyword.get(opts, :group_id) == group_id end
        )

      {:ok, filtered_specs}
    end
  end
end
