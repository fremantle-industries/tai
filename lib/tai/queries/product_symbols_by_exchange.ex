defmodule Tai.Queries.ProductSymbolsByExchange do
  @moduledoc """
  Query module which returns a map of exchanges with their product symbols 
  """

  @spec all :: map
  def all do
    Tai.Exchanges.ProductStore.all()
    |> Enum.reduce(
      %{},
      fn p, acc ->
        exchange_products = Map.get(acc, p.exchange_id, [])
        Map.put(acc, p.exchange_id, [p.symbol | exchange_products])
      end
    )
  end
end
