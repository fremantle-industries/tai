defmodule Tai.Venue do
  alias __MODULE__

  @type id :: atom
  @type adapter :: Tai.Venues.Adapter.t()
  @type channel :: atom
  @type account :: Tai.Venues.Account.t()
  @type credential_id :: atom
  @type credential :: map
  @type credentials :: %{optional(credential_id) => account}
  @type t :: %Venue{
          id: id,
          adapter: adapter,
          channels: [channel],
          products:
            String.t()
            | {module, func_name :: atom}
            | {module, func_name :: atom, func_args :: list},
          accounts: String.t() | {module, func_name :: atom},
          credentials: credentials,
          quote_depth: pos_integer,
          timeout: non_neg_integer,
          start_on_boot: boolean,
          broadcast_change_set: boolean,
          opts: map
        }

  @enforce_keys ~w(
    id
    adapter
    channels
    products
    accounts
    credentials
    quote_depth
    timeout
    start_on_boot
    opts
  )a
  defstruct ~w(
    id
    adapter
    channels
    products
    accounts
    credentials
    quote_depth
    timeout
    start_on_boot
    broadcast_change_set
    opts
  )a
end

defimpl Stored.Item, for: Tai.Venue do
  @type key :: Tai.Venue.id()
  @type venue :: Tai.Venue.t()

  @spec key(venue) :: key
  def key(v), do: v.id
end
