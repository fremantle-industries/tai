defmodule Tai.Advisors.Specs do
  alias Tai.Advisors.{Groups, Spec, SpecStore}

  @type store_id :: SpecStore.store_id()
  @type config :: Tai.Config.t()
  @type spec :: Spec.t()

  @spec from_config(config) :: [spec]
  def from_config(config, provider \\ Groups.RichConfigProvider) do
    {:ok, groups} = Groups.from_config(config.advisor_groups, provider)

    groups
    |> Enum.flat_map(fn group ->
      group.factory.advisor_specs(group)
    end)
  end

  @spec where(list, store_id) :: [spec]
  def where(filters, store_id \\ SpecStore.default_store_id()) do
    store_id
    |> SpecStore.all()
    |> Enumerati.filter(filters)
  end
end
