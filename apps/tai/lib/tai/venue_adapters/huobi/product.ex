defmodule Tai.VenueAdapters.Huobi.Product do
  alias ExHuobi.Futures

  @date_format "{YYYY}{0M}{0D}"
  @date_time_format "#{@date_format} {h24}:{m}"
  @settlement_time "16:00"
  @zone "Etc/UTC"

  def build(%Futures.Contract{} = contract, venue_id) do
    listing = contract.create_date |> Timex.parse!(@date_format) |> DateTime.from_naive!(@zone)

    expiry =
      "#{contract.delivery_date} #{@settlement_time}"
      |> Timex.parse!(@date_time_format)
      |> DateTime.from_naive!(@zone)

    build_product(
      type: :future,
      venue_id: venue_id,
      venue_symbol: contract.contract_code,
      alias: contract.contract_type,
      base: contract.symbol,
      quote: "USD",
      listing: listing,
      expiry: expiry,
      venue_status: contract.contract_status,
      venue_price_increment: contract.price_tick,
      venue_size_increment: 1,
      value: contract.contract_size,
      is_inverse: true,
      is_quanto: false
    )
  end

  def to_symbol(instrument_id) do
    instrument_id
    |> String.replace("-", "_")
    |> downcase_and_atom
  end

  defp downcase_and_atom(str), do: str |> String.downcase() |> String.to_atom()

  defp build_product(args) do
    venue_symbol = Keyword.fetch!(args, :venue_symbol)
    product_alias = args |> Keyword.get(:alias)
    venue_size_increment = Keyword.fetch!(args, :venue_size_increment)

    symbol = venue_symbol |> to_symbol()

    price_increment =
      args |> Keyword.fetch!(:venue_price_increment) |> Tai.Utils.Decimal.cast!(:normalize)

    size_increment = venue_size_increment |> Tai.Utils.Decimal.cast!(:normalize)

    min_size =
      args
      |> Keyword.get(:venue_min_size, venue_size_increment)
      |> Tai.Utils.Decimal.cast!(:normalize)

    value = args |> Keyword.fetch!(:value) |> Tai.Utils.Decimal.cast!(:normalize)
    listing = args |> Keyword.get(:listing)
    expiry = args |> Keyword.get(:expiry)
    base_asset = Keyword.fetch!(args, :base)
    quote_asset = Keyword.fetch!(args, :quote)
    status = args |> Keyword.fetch!(:venue_status) |> to_status()

    %Tai.Venues.Product{
      venue_id: Keyword.fetch!(args, :venue_id),
      symbol: symbol,
      venue_symbol: venue_symbol,
      alias: product_alias,
      base: base_asset |> downcase_and_atom(),
      quote: quote_asset |> downcase_and_atom(),
      venue_base: base_asset,
      venue_quote: quote_asset,
      status: status,
      type: Keyword.fetch!(args, :type),
      listing: listing,
      expiry: expiry,
      collateral: false,
      price_increment: price_increment,
      size_increment: size_increment,
      min_price: price_increment,
      min_size: min_size,
      value: value,
      is_quanto: Keyword.fetch!(args, :is_quanto),
      is_inverse: Keyword.fetch!(args, :is_inverse)
    }
  end

  defp to_status(1), do: :trading
  defp to_status(3), do: :halt
  defp to_status(8), do: :settled
  defp to_status(_), do: :unknown
end
