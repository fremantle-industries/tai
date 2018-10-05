defmodule Tai.TestSupport.Mocks.Responses.MakerTakerFees do
  @spec for_exchange_and_account(
          exchange_id :: atom,
          account_id :: atom,
          {maker :: Decimal.t(), taker :: Decimal.t()}
        ) :: :ok
  def for_exchange_and_account(exchange_id, account_id, {_, _} = maker_taker_fees) do
    key = Tai.ExchangeAdapters.New.Mock.maker_taker_fees_response_key({exchange_id, account_id})
    :ok = Tai.TestSupport.Mocks.Server.insert(key, maker_taker_fees)

    :ok
  end
end
