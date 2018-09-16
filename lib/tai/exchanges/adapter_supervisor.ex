defmodule Tai.Exchanges.AdapterSupervisor do
  @callback hydrate_products() :: atom
  @callback hydrate_fees() :: atom
  @callback account() :: atom

  defmacro __using__(_) do
    quote location: :keep do
      use Supervisor

      @behaviour Tai.Exchanges.AdapterSupervisor

      def start_link(%Tai.Exchanges.Config{} = config) do
        name = :"#{__MODULE__}_#{config.id}"
        Supervisor.start_link(__MODULE__, config, name: name)
      end

      def init(config) do
        [
          {Tai.Exchanges.AccountsSupervisor,
           [adapter: account(), exchange_id: config.id, accounts: config.accounts]},
          {hydrate_products(), [exchange_id: config.id, whitelist_query: config.products]},
          {hydrate_fees(), [exchange_id: config.id, accounts: config.accounts]},
          {Tai.Exchanges.HydrateAssetBalances,
           [exchange_id: config.id, accounts: config.accounts]}
        ]
        |> Supervisor.init(strategy: :one_for_one)
      end
    end
  end
end
