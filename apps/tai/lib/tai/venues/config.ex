defmodule Tai.Venues.Config do
  @type config :: Tai.Config.t()

  @spec parse() :: map
  @spec parse(config) :: map
  def parse(%Tai.Config{} = config \\ Tai.Config.parse()) do
    config.venues
    |> Enum.reduce(
      %{},
      fn
        {id, params}, acc ->
          if Keyword.get(params, :enabled, false) do
            venue = %Tai.Venue{
              id: id,
              adapter: Keyword.fetch!(params, :adapter),
              channels: Keyword.get(params, :channels, []),
              products: Keyword.get(params, :products, "*"),
              accounts: Keyword.get(params, :accounts, "*"),
              credentials: Keyword.get(params, :credentials, %{}),
              quote_depth: Keyword.get(params, :quote_depth, 1),
              opts: Keyword.get(params, :opts, %{}),
              timeout: Keyword.get(params, :timeout, config.adapter_timeout),
              broadcast_change_set:
                Keyword.get(params, :broadcast_change_set, config.broadcast_change_set)
            }

            Map.put(acc, id, venue)
          else
            acc
          end
      end
    )
  end
end
