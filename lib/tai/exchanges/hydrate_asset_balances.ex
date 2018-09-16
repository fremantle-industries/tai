defmodule Tai.Exchanges.HydrateAssetBalances do
  use GenServer

  def start_link([exchange_id: exchange_id, accounts: _] = state) do
    name = :"#{__MODULE__}_#{exchange_id}"
    GenServer.start_link(__MODULE__, state, name: name)
  end

  def init(state) do
    {:ok, state, {:continue, :fetch}}
  end

  def handle_continue(:fetch, state) do
    fetch!(state)
    {:noreply, state}
  end

  defp fetch!(exchange_id: exchange_id, accounts: accounts) do
    accounts
    |> Enum.map(fn {account_id, _} ->
      with {:ok, balances} <- Tai.Exchanges.Account.all_balances(exchange_id, account_id) do
        balances
        |> Enum.map(fn {asset, balance} ->
          Tai.Exchanges.AssetBalances.upsert(exchange_id, account_id, asset, balance)
        end)
      end
    end)
  end
end
