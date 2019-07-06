defmodule Tai.Advisors.Spec do
  @type mod :: atom
  @type group_id :: Tai.AdvisorGroup.id()
  @type advisor_id :: Tai.Advisor.id()
  @type product :: Tai.Venues.Product.t()
  @type config :: map
  @type spec_opts :: [
          group_id: group_id,
          advisor_id: advisor_id,
          products: [product],
          config: config
        ]
  @type t :: %Tai.Advisors.Spec{
          mod: mod,
          start_on_boot: boolean,
          group_id: group_id,
          advisor_id: advisor_id,
          products: [product],
          config: config
        }

  @enforce_keys ~w(mod start_on_boot group_id advisor_id products config)a
  defstruct ~w(mod start_on_boot group_id advisor_id products config)a

  @spec to_child_spec(t) :: {mod, spec_opts}
  def to_child_spec(spec) do
    opts = [
      group_id: spec.group_id,
      advisor_id: spec.advisor_id,
      products: spec.products,
      config: spec.config
    ]

    {spec.mod, opts}
  end
end
