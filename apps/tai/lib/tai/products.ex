defmodule Tai.Products do
  alias __MODULE__

  def product_symbols_by_venue do
    Products.Queries.ProductSymbolsByVenue.call()
  end
end
