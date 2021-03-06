defmodule Tai.Venues.Instance do
  alias __MODULE__

  @type id :: atom
  @type adapter :: Tai.Venues.Adapter.t()
  @type channel :: atom
  @type account :: Tai.Venues.Account.t()
  @type credential_id :: atom
  @type credential :: map
  @type credentials :: %{optional(credential_id) => account}
  @type status :: :stopped | :starting | :running | :error
  @type t :: %Instance{
          id: id,
          adapter: adapter,
          channels: [channel],
          products: String.t() | {module, func_name :: atom},
          accounts: String.t() | {module, func_name :: atom},
          credentials: credentials,
          quote_depth: pos_integer,
          funding_rates_enabled: boolean,
          timeout: non_neg_integer,
          start_on_boot: boolean,
          broadcast_change_set: boolean,
          opts: map,
          status: status
        }

  @enforce_keys ~w(
    id
    adapter
    channels
    products
    accounts
    credentials
    quote_depth
    funding_rates_enabled
    timeout
    start_on_boot
    opts
    status
  )a
  defstruct ~w(
    id
    adapter
    channels
    products
    accounts
    credentials
    quote_depth
    funding_rates_enabled
    timeout
    start_on_boot
    broadcast_change_set
    opts
    status
  )a
end
