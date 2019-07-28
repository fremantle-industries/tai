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
          group_id: group_id,
          advisor_id: advisor_id,
          products: [product],
          config: config,
          run_store: run_store | nil,
          trades: trades | nil
        }

  @enforce_keys ~w(mod start_on_boot group_id advisor_id products config)a
  defstruct ~w(mod start_on_boot group_id advisor_id products config run_store trades)a

  @spec to_child_spec(t) :: Supervisor.child_spec()
  def to_child_spec(spec) do
    run_store = spec.run_store || %{}
    trades = spec.trades || []
    name = Tai.Advisor.to_name(spec.group_id, spec.advisor_id)

    start_opts = [
      group_id: spec.group_id,
      advisor_id: spec.advisor_id,
      products: spec.products,
      config: spec.config,
      store: run_store,
      trades: trades
    ]

    %{
      id: name,
      start: {spec.mod, :start_link, [start_opts]},
      type: :worker,
      restart: :temporary,
      shutdown: 5000
    }
  end
end
