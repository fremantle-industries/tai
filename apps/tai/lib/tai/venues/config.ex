defmodule Tai.Venues.Config do
  @type config :: Tai.Config.t()
  @type venue :: Tai.Venue.t()

  @spec parse() :: [venue]
  @spec parse(config) :: [venue]
  def parse(%Tai.Config{} = config \\ Tai.Config.parse()) do
    config.venues
    |> Enum.map(fn {id, params} ->
      %Tai.Venue{
        id: id,
        adapter: Keyword.fetch!(params, :adapter),
        channels: Keyword.get(params, :channels, []),
        products: Keyword.get(params, :products, "*"),
        accounts: Keyword.get(params, :accounts, "*"),
        credentials: Keyword.get(params, :credentials, %{}),
        quote_depth: Keyword.get(params, :quote_depth, 1),
        start_on_boot: Keyword.get(params, :start_on_boot, true),
        opts: Keyword.get(params, :opts, %{}),
        timeout: Keyword.get(params, :timeout, config.adapter_timeout),
        broadcast_change_set:
          Keyword.get(params, :broadcast_change_set, config.broadcast_change_set)
      }
    end)
  end
end
