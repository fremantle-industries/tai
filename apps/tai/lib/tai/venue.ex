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
          products: String.t() | function,
          accounts: String.t() | function,
          credentials: credentials,
          quote_depth: pos_integer,
          timeout: non_neg_integer,
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
    opts
  )a
end
