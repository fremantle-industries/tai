defmodule Tai.AdvisorGroups.BuildSpecsForAdvisor do
  @type config :: Tai.Config.t()
  @type advisor_spec :: {atom, [group_id: atom, advisor_id: atom, order_books: map, store: map]}
  @type product :: Tai.Venues.Product.t()

  @spec build_specs_for_advisor(config, group_id :: atom, advisor_id :: atom, [product]) ::
          {:ok, [advisor_spec]} | {:error, map}
  def build_specs_for_advisor(
        %Tai.Config{} = config,
        group_id,
        advisor_id,
        products \\ Tai.Venues.ProductStore.all()
      ) do
    with {:ok, specs} <- Tai.AdvisorGroups.build_specs(config, products) do
      filtered_specs =
        specs
        |> Enum.filter(fn {_, opts} -> Keyword.get(opts, :group_id) == group_id end)
        |> Enum.filter(fn {_, opts} -> Keyword.get(opts, :advisor_id) == advisor_id end)

      {:ok, filtered_specs}
    end
  end
end
