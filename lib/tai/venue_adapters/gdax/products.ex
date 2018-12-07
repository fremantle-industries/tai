defmodule Tai.VenueAdapters.Gdax.Products do
  @moduledoc """
  Retrieves the available products on the GDAX exchange
  """

  @type error_reason ::
          :timeout
          | Tai.CredentialError.t()
          | Tai.CredentialError.t()
          | Tai.ServiceUnavailableError.t()
  @type products :: Tai.Venues.Product.t()

  @spec products(venue_id :: atom) :: {:ok, [products]} | {:error, error_reason}
  def products(venue_id) do
    with {:ok, exchange_products} <- ExGdax.list_products() do
      products = Enum.map(exchange_products, &build(&1, venue_id))
      {:ok, products}
    else
      {:error, "Invalid Passphrase" = reason, _status} ->
        {:error, %Tai.CredentialError{reason: reason}}

      {:error, "Invalid API Key" = reason, _status} ->
        {:error, %Tai.CredentialError{reason: reason}}

      {:error, reason, 503} ->
        {:error, %Tai.ServiceUnavailableError{reason: reason}}

      {:error, "timeout"} ->
        {:error, :timeout}
    end
  end

  defp build(
         %{
           "base_currency" => base_asset,
           "quote_currency" => quote_asset,
           "id" => id,
           "status" => exchange_status,
           "base_min_size" => raw_base_min_size,
           "base_max_size" => raw_base_max_size,
           "quote_increment" => raw_quote_increment
         },
         venue_id
       ) do
    symbol = Tai.Symbol.build(base_asset, quote_asset)
    {:ok, status} = Tai.VenueAdapters.Gdax.ProductStatus.normalize(exchange_status)
    base_min_size = raw_base_min_size |> to_decimal
    base_max_size = raw_base_max_size |> to_decimal
    quote_increment = raw_quote_increment |> to_decimal
    min_notional = Decimal.mult(base_min_size, quote_increment)

    %Tai.Venues.Product{
      exchange_id: venue_id,
      symbol: symbol,
      exchange_symbol: id,
      status: status,
      min_notional: min_notional,
      min_price: quote_increment,
      min_size: base_min_size,
      max_size: base_max_size,
      price_increment: quote_increment,
      size_increment: base_min_size
    }
  end

  defp to_decimal(val) when is_float(val), do: val |> Decimal.from_float()
  defp to_decimal(val), do: val |> Decimal.new()
end
