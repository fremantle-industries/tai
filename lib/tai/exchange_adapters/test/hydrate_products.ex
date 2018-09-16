defmodule Tai.ExchangeAdapters.Test.HydrateProducts do
  use GenServer

  def start_link([exchange_id: _, whitelist_query: _] = state) do
    GenServer.start_link(
      __MODULE__,
      state,
      name: state |> to_name
    )
  end

  def init(exchange_id) do
    {:ok, exchange_id}
  end

  defp to_name(exchange_id: exchange_id, whitelist_query: _) do
    :"#{__MODULE__}_#{exchange_id}"
  end
end
