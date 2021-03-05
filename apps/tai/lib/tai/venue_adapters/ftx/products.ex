defmodule Tai.VenueAdapters.Ftx.Products do
  alias ExFtx.{Futures, Markets, Market}
  alias Tai.VenueAdapters.Ftx

  @date_format "{ISO:Extended}"

  def products(venue_id) do
    with {:ok, markets} <- Markets.List.get(),
         {:ok, futures} <- Futures.List.get() do
      products = markets
                 |> Enum.map(fn
                   %Market{type: "spot"} = market ->
                     Ftx.Product.build(market, venue_id, :spot, nil)

                   market ->
                     future = Enum.find(futures, fn future -> future.name == market.name end)
                     type = if future.perpetual, do: :swap, else: :future
                     expiry = if future.expiry, do: Timex.parse!(future.expiry, @date_format), else: nil
                     Ftx.Product.build(market, venue_id, type, expiry)
                 end)

      {:ok, products}
    end
  end

  defdelegate to_symbol(market_name), to: Ftx.Product
end
