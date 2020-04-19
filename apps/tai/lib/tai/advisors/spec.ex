defmodule Tai.Advisors.Spec do
  @type mod :: atom
  @type group_id :: Tai.AdvisorGroup.id()
  @type advisor_id :: Tai.Advisor.id()
  @type product :: Tai.Venues.Product.t()
  @type run_store :: Tai.Advisor.run_store()
  @type trades :: list
  @type config :: map
  @type spec_opts :: [
          group_id: group_id,
          advisor_id: advisor_id,
          products: [product],
          config: config,
          store: run_store,
          trades: trades
        ]
  @type t :: %Tai.Advisors.Spec{
          mod: mod,
          start_on_boot: boolean,
          restart: Tai.AdvisorGroup.restart(),
          shutdown: Tai.AdvisorGroup.shutdown(),
          group_id: group_id,
          advisor_id: advisor_id,
          products: [product],
          config: config,
          run_store: run_store | nil,
          trades: trades | nil
        }

  @enforce_keys ~w[mod start_on_boot restart shutdown group_id advisor_id products config]a
  defstruct ~w[mod start_on_boot restart shutdown group_id advisor_id products config run_store trades]a

  defimpl Stored.Item do
    @type spec :: Tai.Advisors.Spec.t()
    @type group_id :: Tai.AdvisorGroup.id()
    @type advisor_id :: Tai.Advisor.id()

    @spec key(spec) :: {group_id, advisor_id}
    def key(spec), do: {spec.group_id, spec.advisor_id}
  end
end
