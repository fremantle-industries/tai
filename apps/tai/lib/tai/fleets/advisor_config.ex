defmodule Tai.Fleets.AdvisorConfig do
  @type advisor_id :: atom
  @type fleet_id :: Tai.Fleets.FleetConfig.id()
  @type venue :: String.t()
  @type product_symbol :: String.t()
  @type market_stream_keys :: [{venue, product_symbol}]
  @type t :: %__MODULE__{
    advisor_id: advisor_id,
    fleet_id: fleet_id,
    start_on_boot: boolean,
    restart: :permanent | :transient | :temporary,
    shutdown: timeout | :brutal_kill,
    market_stream_keys: market_stream_keys,
    config: struct | map,
    mod: module,
    instance_supervisor: module | nil
  }

  @enforce_keys ~w[
    advisor_id
    fleet_id
    start_on_boot
    restart
    shutdown
    market_stream_keys
    config
    mod
  ]a
  defstruct ~w[
    advisor_id
    fleet_id
    start_on_boot
    restart
    shutdown
    market_stream_keys
    config
    mod
    instance_supervisor
  ]a

  defimpl Stored.Item do
    def key(a), do: {a.advisor_id, a.fleet_id}
  end
end
