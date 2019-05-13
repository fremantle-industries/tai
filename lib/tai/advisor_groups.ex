defmodule Tai.AdvisorGroups do
  @type group :: Tai.AdvisorGroup.t()
  @type advisor_spec :: Tai.Advisor.spec()

  @spec specs(group, list) :: [advisor_spec]
  def specs(%Tai.AdvisorGroup{factory: factory} = group, filters \\ []) do
    if allow?(group, filters) do
      group |> factory.advisor_specs()
    else
      []
    end
  end

  defp allow?(group, filters) do
    start_on_boot = filters |> Keyword.get(:start_on_boot)
    group_id = filters |> Keyword.get(:group_id)
    allow_start_on_boot = start_on_boot == group.start_on_boot || start_on_boot == nil
    allow_group_id = group_id == group.id || group_id == nil

    allow_start_on_boot && allow_group_id
  end
end
