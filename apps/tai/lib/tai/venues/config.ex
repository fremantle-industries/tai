defmodule Tai.Venues.Config do
  @moduledoc """
  Venue configuration for a `tai` instance. This module provides a utility
  function `Tai.Venues.Config.parse/0` that hydrates a list of venues from
  the `%Tai.Config{}`.

  It can be configured with the following options:

  ```
  config :tai,
    venues: %{
      okex: [
        # Module that implements the `Tai.Venues.Adapter` behaviour
        adapter: Tai.VenueAdapters.OkEx,

        # [default: %Tai.Config#adapter_timeout] [optional] Per venue override for start
        # timeout in milliseconds
        timeout: 120_000,

        # [default: true] [optional] Starts the venue on initial boot
        start_on_boot: true,

        # [default: []] [optional] Subscribe to venue specific channels
        channels: [],

        # [default: "*"] [optional] A `juice` query matching on alias and symbol, or `{module, func_name}`
        # to filter available products. Juice query syntax is described in more detail at
        # https://github.com/rupurt/juice#usage
        products: "eth_usd_200925 eth_usd_bi_quarter",

        # [default: 1] [optional] The number of streaming order book levels to maintain. This
        # value has adapter specific support. For example some venues may only allow you to
        # subscribe in blocks of 5 price points. So supported values for that venue
        # are `5`, `10`, `15`, ...
        quote_depth: 1,

        # [default: "*"] [optional] A juice query matching on asset to filter available accounts.
        # Juice query syntax is described in more detail at https://github.com/rupurt/juice#usage
        accounts: "*",

        # [default: %{}] [optional] `Map` of named credentials to use private API's on the venue
        credentials: %{
          main: %{
            api_key: {:system_file, "OKEX_API_KEY"},
            api_secret: {:system_file, "OKEX_API_SECRET"},
            api_passphrase: {:system_file, "OKEX_API_PASSPHRASE"}
          }
        },

        # [default: %{}] [optional] `Map` of extra venue configuration parameters for non-standard
        # tai functionality.
        opts: %{},
      ]
    }
  ```
  """

  @type venue :: Tai.Venue.t()

  @spec parse() :: [venue]
  @spec parse(Tai.Config.t()) :: [venue]
  def parse(config \\ Tai.Config.parse()) do
    config.venues
    |> Enum.map(fn {id, params} ->
      %Tai.Venue{
        id: id,
        adapter: fetch!(params, :adapter),
        channels: get(params, :channels, []),
        products: get(params, :products, "*"),
        accounts: get(params, :accounts, "*"),
        credentials: get(params, :credentials, %{}),
        quote_depth: get(params, :quote_depth, 1),
        start_on_boot: get(params, :start_on_boot, true),
        opts: get(params, :opts, %{}),
        timeout: get(params, :timeout, config.adapter_timeout),
        broadcast_change_set: get(params, :broadcast_change_set, config.broadcast_change_set)
      }
    end)
  end

  defp get(env, key, default), do: Keyword.get(env, key, default)
  defp fetch!(env, key), do: Keyword.fetch!(env, key)
end
