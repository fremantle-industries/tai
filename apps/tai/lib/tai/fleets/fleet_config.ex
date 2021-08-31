defmodule Tai.Fleets.FleetConfig do
  @type id :: atom
  @type t :: %__MODULE__{
    id: id,
    start_on_boot: boolean,
    restart: :permanent | :transient | :temporary,
    shutdown: timeout | :brutal_kill,
    quotes: String.t(),
    factory: module,
    advisor: module,
    config: struct | map
  }

  @enforce_keys ~w[id start_on_boot restart shutdown quotes factory advisor]a
  defstruct ~w[id start_on_boot restart shutdown quotes factory advisor config]a

  defimpl Stored.Item do
    def key(f), do: f.id
  end
end
