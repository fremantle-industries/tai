defmodule Tai.TestSupport.Mocks.Responses.AssetBalances do
  def for_exchange_and_account(exchange_id, account_id, balances_attrs) do
    balances =
      balances_attrs
      |> Enum.map(fn attrs ->
        struct(
          Tai.Exchanges.AssetBalance,
          Map.merge(%{exchange_id: exchange_id, account_id: account_id}, attrs)
        )
      end)

    key = Tai.ExchangeAdapters.New.Mock.asset_balances_response_key({exchange_id, account_id})
    :ok = Tai.TestSupport.Mocks.Server.insert(key, balances)

    :ok
  end
end
