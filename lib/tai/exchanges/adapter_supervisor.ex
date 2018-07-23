defmodule Tai.Exchanges.AdapterSupervisor do
  @callback products() :: atom

  defmacro __using__(_) do
    quote location: :keep do
      use Supervisor

      @behaviour Tai.Exchanges.AdapterSupervisor

      def start_link(%Tai.Exchanges.Config{} = config) do
        Supervisor.start_link(
          __MODULE__,
          config,
          name: :"#{__MODULE__}_#{config.id}"
        )
      end

      def init(%Tai.Exchanges.Config{id: exchange_id, products: products}) do
        [
          {products(), [exchange_id: exchange_id, whitelist_query: products]}
        ]
        |> Supervisor.init(strategy: :one_for_one)
      end
    end
  end
end
