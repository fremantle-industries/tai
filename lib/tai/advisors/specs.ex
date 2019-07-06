defmodule Tai.Advisors.Specs do
  alias Tai.Advisors.{Groups, Spec}

  @type config :: Tai.Config.t()
  @type spec :: Spec.t()

  @spec from_config(config) :: [spec]
  def from_config(config, provider \\ Groups.RichConfigProvider) do
    {:ok, groups} = Groups.parse_config(config, provider)

    groups
    |> Enum.flat_map(fn group ->
      group.factory.advisor_specs(group)
    end)
  end
end
