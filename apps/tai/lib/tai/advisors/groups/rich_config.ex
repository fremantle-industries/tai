defmodule Tai.Advisors.Groups.RichConfig do
  alias Tai.Advisors.Groups.RichConfigProvider

  @type config :: map
  @type provider :: module

  @spec parse(config, provider) :: config
  def parse(raw_config, provider \\ RichConfigProvider) do
    raw_config |> Enum.reduce(%{}, &parse_item(&1, &2, provider))
  end

  defp parse_item({k, {{venue_id, product_symbol}, :product}}, acc, provider) do
    product = provider.products |> find_product(venue_id, product_symbol)
    acc |> Map.put(k, product)
  end

  defp parse_item({k, {{venue_id, product_symbol, credential_id}, :fee}}, acc, provider) do
    fee = provider.fees |> find_fee(venue_id, product_symbol, credential_id)
    acc |> Map.put(k, fee)
  end

  defp parse_item({k, {raw_val, :decimal}}, acc, _provider) do
    decimal_val = Tai.Utils.Decimal.cast!(raw_val)
    acc |> Map.put(k, decimal_val)
  end

  defp parse_item({k, v}, acc, _provider), do: acc |> Map.put(k, v)

  defp find_product(products, venue_id, symbol) do
    products |> Enum.find(fn p -> p.venue_id == venue_id && p.symbol == symbol end)
  end

  defp find_fee(fees, venue_id, symbol, credential_id) do
    fees
    |> Enum.find(fn f ->
      f.venue_id == venue_id && f.symbol == symbol && f.credential_id == credential_id
    end)
  end
end
