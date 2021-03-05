defmodule Tai.VenueAdapters.Ftx.Product do
  alias ExFtx.Market

  defmodule Options do
    @type t :: %Options{
      type: Tai.Venues.Product.type(),
      collateral: Tai.Venues.Product.collateral(),
      expiry: Tai.Venues.Product.expiry()
    }

    @enforce_keys ~w[type collateral]a
    defstruct ~w[type collateral expiry]a
  end

  def build(%Market{} = market, venue_id, options) do
    # TODO: Figure out what this should be
    value = 1_000_000 |> Tai.Utils.Decimal.cast!()

    %Tai.Venues.Product{
      venue_id: venue_id,
      symbol: market.name |> to_symbol,
      venue_symbol: market.name,
      alias: nil,
      base: market |> base_currency(),
      quote: market |> quote_currency(),
      venue_base: market.base_currency,
      venue_quote: market.quote_currency,
      status: market |> status(),
      type: options.type,
      listing: nil,
      expiry: options.expiry,
      collateral: options.collateral,
      price_increment: market.price_increment |> Tai.Utils.Decimal.cast!(),
      size_increment: market.size_increment |> Tai.Utils.Decimal.cast!(),
      min_price: market.price_increment |> Tai.Utils.Decimal.cast!(),
      min_size: market.size_increment |> Tai.Utils.Decimal.cast!(),
      value: value,
      is_quanto: false,
      is_inverse: false
    }
  end

  def to_symbol(market_name), do: market_name |> downcase_and_atom()

  defp status(%Market{enabled: true, restricted: false}), do: :trading
  defp status(%Market{enabled: true, restricted: true}), do: :restricted
  defp status(%Market{enabled: false}), do: :halt

  defp base_currency(%Market{type: "spot"} = m), do: m.base_currency |> downcase_and_atom()
  defp base_currency(m), do: m.underlying |> downcase_and_atom()

  defp quote_currency(%Market{type: "spot"} = m), do: m.quote_currency |> downcase_and_atom()
  defp quote_currency(_), do: :usd

  defp downcase_and_atom(str), do: str |> String.downcase() |> String.to_atom()
end
