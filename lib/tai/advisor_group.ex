defmodule Tai.AdvisorGroup do
  @type t :: %Tai.AdvisorGroup{}

  defstruct [:id, :factory, :products]

  @spec parse_configs(configs :: map) :: {:ok, [t]}
  def parse_configs(configs \\ Application.get_env(:tai, :advisor_groups)) when is_map(configs) do
    results =
      configs
      |> Enum.reduce(
        %{groups: [], errors: %{}},
        fn {id, config}, acc ->
          errors = []

          factory = Keyword.get(config, :factory)
          errors = if factory == nil, do: [:factory_not_present | errors], else: errors

          products = Keyword.get(config, :products)
          errors = if products == nil, do: [:products_not_present | errors], else: errors

          if Enum.empty?(errors) do
            group = %Tai.AdvisorGroup{
              id: id,
              factory: factory,
              products: products
            }

            new_groups = acc.groups ++ [group]
            Map.put(acc, :groups, new_groups)
          else
            group_errors = Map.put(acc.errors, id, errors)
            Map.put(acc, :errors, group_errors)
          end
        end
      )

    if Enum.empty?(results.errors) do
      {:ok, results.groups}
    else
      {:error, results.errors}
    end
  end
end
