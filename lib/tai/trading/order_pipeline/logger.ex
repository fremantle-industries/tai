defmodule Tai.Trading.OrderPipeline.Logger do
  require Logger

  def info(%Tai.Trading.Order{} = order) do
    Logger.info(fn ->
      :io_lib.format(
        "[order:~s,~s,~s,~s,~s,~s,~s,~s,~s,~s,~s]",
        [
          order.client_id,
          order.status,
          order.exchange_id,
          order.account_id,
          order.symbol,
          order.side,
          order.type,
          order.time_in_force,
          order.price |> Decimal.to_string(:normal),
          order.size |> Decimal.to_string(:normal),
          order.error_reason || ""
        ]
      )
    end)
  end
end
