defmodule Tai.AdvisorGroups.ParseConfig do
  @type config :: Tai.Config.t()
  @type advisor_group :: Tai.AdvisorGroup.t()
  @type product :: Tai.Venues.Product.t()

  @spec parse_config(config) :: {:ok, [advisor_group]} | {:error, map}
  def parse_config(%Tai.Config{advisor_groups: advisor_groups}) do
    {groups, errors} = advisor_groups |> Enum.reduce({[], %{}}, &build_group/2)
    if Enum.empty?(errors), do: {:ok, groups}, else: {:error, errors}
  end

  defp build_group({id, config}, {groups, errors}) do
    group = %Tai.AdvisorGroup{
      id: id,
      advisor: config |> Keyword.get(:advisor),
      factory: config |> Keyword.get(:factory),
      products: config |> Keyword.get(:products),
      config: config |> Keyword.get(:config, %{})
    }

    if Vex.valid?(group) do
      new_groups = groups ++ [group]
      {new_groups, errors}
    else
      group_errors =
        group
        |> Vex.errors()
        |> Enum.map(fn {:error, k, _, m} -> {k, m} end)

      new_errors = Map.put(errors, id, group_errors)
      {groups, new_errors}
    end
  end
end
