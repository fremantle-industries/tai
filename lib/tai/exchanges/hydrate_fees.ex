defmodule Tai.Exchanges.HydrateFees do
  @doc """
  Fetch the maker/taker fees for the account on the exchange
  """
  @callback maker_taker(exchange_id :: atom, account_id :: atom) ::
              {:ok, {maker :: Decimal.t(), taker :: Decimal.t()}}

  defmacro __using__(_) do
    quote location: :keep do
      use GenServer

      @behaviour Tai.Exchanges.HydrateFees

      def start_link([exchange_id: exchange_id, accounts: _] = state) do
        name = :"#{__MODULE__}_#{exchange_id}"
        GenServer.start_link(__MODULE__, state, name: name)
      end

      def init([exchange_id: exchange_id, accounts: _] = state) do
        Tai.Boot.subscribe_products(exchange_id)
        {:ok, state}
      end

      def handle_info(
            {:fetched_products, :ok, _},
            [exchange_id: exchange_id, accounts: accounts] = state
          ) do
        products = Tai.Exchanges.ProductStore.where(exchange_id: exchange_id)

        accounts
        |> Map.keys()
        |> Enum.each(fn account_id ->
          {:ok, {maker, taker}} = maker_taker(exchange_id, account_id)

          products
          |> Enum.each(fn %Tai.Exchanges.Product{symbol: symbol} ->
            fee_info = %Tai.Exchanges.FeeInfo{
              exchange_id: exchange_id,
              account_id: account_id,
              symbol: symbol,
              maker: maker,
              maker_type: Tai.Exchanges.FeeInfo.percent(),
              taker: taker,
              taker_type: Tai.Exchanges.FeeInfo.percent()
            }

            Tai.Exchanges.Fees.upsert(fee_info)
          end)

          Tai.Boot.hydrated_fees(exchange_id, account_id)
        end)

        {:noreply, state}
      end
    end
  end
end
