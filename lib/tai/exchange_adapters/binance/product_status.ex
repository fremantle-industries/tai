defmodule Tai.ExchangeAdapters.Binance.ProductStatus do
  @type product_status :: Tai.Exchanges.ProductStatus.t()

  @spec tai_status(:term) :: {:ok, product_status} | {:error, :unknown_status}
  def tai_status(_)
  def tai_status("PRE_TRADING"), do: {:ok, Tai.Exchanges.ProductStatus.pre_trading()}
  def tai_status("TRADING"), do: {:ok, Tai.Exchanges.ProductStatus.trading()}
  def tai_status("POST_TRADING"), do: {:ok, Tai.Exchanges.ProductStatus.post_trading()}
  def tai_status("END_OF_DAY"), do: {:ok, Tai.Exchanges.ProductStatus.end_of_day()}
  def tai_status("HALT"), do: {:ok, Tai.Exchanges.ProductStatus.halt()}
  def tai_status("AUCTION_MATCH"), do: {:ok, Tai.Exchanges.ProductStatus.auction_match()}
  def tai_status("BREAK"), do: {:ok, Tai.Exchanges.ProductStatus.break()}
  def tai_status(_), do: {:error, :unknown_status}
end
