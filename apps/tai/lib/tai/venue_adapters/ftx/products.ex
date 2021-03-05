defmodule Tai.VenueAdapters.Ftx.Products do
  alias ExFtx.{Wallet, Futures, Markets, Market}
  alias Tai.VenueAdapters.Ftx

  @date_format "{ISO:Extended}"

  def products(venue_id) do
    with {:ok, coins} <- Wallet.Coins.get(),
         {:ok, futures} <- Futures.List.get(),
         {:ok, markets} <- Markets.List.get() do
      products = markets
                 |> Enum.map(fn
                   %Market{type: "spot"} = market ->
                     coin = Enum.find(coins, fn coin -> coin.id == market.base_currency end)
                     options = %Ftx.Product.Options{type: :spot, collateral: coin.collateral}
                     Ftx.Product.build(market, venue_id, options)

                   market ->
                     future = Enum.find(futures, fn future -> future.name == market.name end)
                     type = if future.perpetual, do: :swap, else: :future
                     expiry = if future.expiry, do: Timex.parse!(future.expiry, @date_format), else: nil
                     options = %Ftx.Product.Options{type: type, collateral: false, expiry: expiry}
                     Ftx.Product.build(market, venue_id, options)
                 end)

      {:ok, products}
    end
  end

  defdelegate to_symbol(market_name), to: Ftx.Product
end
