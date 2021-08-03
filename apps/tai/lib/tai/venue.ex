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
          order_books:
            String.t()
            | {module, func_name :: atom}
            | {module, func_name :: atom, func_args :: list},
          accounts: String.t() | {module, func_name :: atom},
          credentials: credentials,
          quote_depth: pos_integer,
          timeout: pos_integer,
          stream_heartbeat_interval: pos_integer,
          stream_heartbeat_timeout: pos_integer,
          start_on_boot: boolean,
          broadcast_change_set: boolean,
          opts: map
        }

  @enforce_keys ~w(
    id
    adapter
    channels
    products
    order_books
    accounts
    credentials
    quote_depth
    timeout
    stream_heartbeat_interval
    stream_heartbeat_timeout
    start_on_boot
    opts
  )a
  defstruct ~w(
    id
    adapter
    channels
    products
    order_books
    accounts
    credentials
    quote_depth
    timeout
    stream_heartbeat_interval
    stream_heartbeat_timeout
    start_on_boot
    broadcast_change_set
    opts
  )a

  defimpl Stored.Item do
    @type key :: Tai.Venue.id()
    @type venue :: Tai.Venue.t()

    @spec key(venue) :: key
    def key(v), do: v.id
  end
end
