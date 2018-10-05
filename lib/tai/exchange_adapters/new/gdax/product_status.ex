defmodule Tai.ExchangeAdapters.New.Gdax.ProductStatus do
  @type status :: Tai.Exchanges.ProductStatus.t()

  @spec normalize(gdax_status :: String.t()) :: {:ok, status} | {:error, :unknown_status}
  def normalize(gdax_status)

  def normalize("online"), do: {:ok, Tai.Exchanges.ProductStatus.trading()}
  def normalize(_), do: {:error, :unknown_status}
end
