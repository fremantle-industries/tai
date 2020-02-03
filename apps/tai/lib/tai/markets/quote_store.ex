defmodule Tai.Markets.QuoteStore do
  use Stored.Store

  @topic :market_quote_store

  def after_backend_create do
    Tai.PubSub.subscribe(:market_quote)
  end

  def handle_info({:tai, %Tai.Markets.Quote{} = market_quote}, state) do
    {:ok, _} = state.backend.put(market_quote, state.name)
    @topic |> Tai.PubSub.broadcast({:market_quote_store_upserted, market_quote})

    {:noreply, state}
  end
end
