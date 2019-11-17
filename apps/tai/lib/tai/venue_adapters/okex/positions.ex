defmodule Tai.VenueAdapters.OkEx.Positions do
  def positions(venue_id, account_id, credentials) do
    venue_credentials = to_venue_credentials(credentials)

    with {:ok, swap_venue_positions} <- ExOkex.Swap.Private.list_positions(venue_credentials),
         {:ok, futures_venue_positions} <-
           ExOkex.Futures.Private.list_positions(venue_credentials) do
      swap_positions = swap_venue_positions |> Enum.map(&build_swap(&1, venue_id, account_id))

      futures_positions =
        futures_venue_positions |> Enum.flat_map(&build_futures(&1, venue_id, account_id))

      positions = swap_positions ++ futures_positions

      {:ok, positions}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp to_venue_credentials(credentials), do: struct(ExOkex.Config, credentials)

  def build_swap(venue_position, venue_id, account_id) do
    %Tai.Trading.Position{
      venue_id: venue_id,
      account_id: account_id,
      product_symbol: venue_position |> product_symbol(),
      side: venue_position |> swap_side(),
      qty: venue_position.position |> Decimal.new(),
      entry_price: venue_position.avg_cost |> Decimal.new(),
      margin_mode: venue_position |> margin_mode(),
      leverage: venue_position |> leverage()
    }
  end

  defp build_futures(venue_position, venue_id, account_id) do
    [
      build_long_future(venue_position, venue_id, account_id),
      build_short_future(venue_position, venue_id, account_id)
    ]
  end

  def build_long_future(venue_position, venue_id, account_id) do
    %Tai.Trading.Position{
      venue_id: venue_id,
      account_id: account_id,
      product_symbol: venue_position |> product_symbol(),
      side: :long,
      qty: venue_position |> futures_qty(:long),
      entry_price: venue_position |> futures_entry_price(:long),
      margin_mode: venue_position |> margin_mode(),
      leverage: venue_position |> leverage()
    }
  end

  def build_short_future(venue_position, venue_id, account_id) do
    %Tai.Trading.Position{
      venue_id: venue_id,
      account_id: account_id,
      product_symbol: venue_position |> product_symbol(),
      side: :short,
      qty: venue_position |> futures_qty(:short),
      entry_price: venue_position |> futures_entry_price(:short),
      margin_mode: venue_position |> margin_mode(),
      leverage: venue_position |> leverage()
    }
  end

  # TODO: This should come from products
  defp product_symbol(venue_position) do
    venue_position.instrument_id
    |> String.downcase()
    |> String.to_atom()
  end

  defp swap_side(%_struct{side: "long"}), do: :long
  defp swap_side(%_struct{side: "short"}), do: :short

  defp futures_qty(%_struct{long_qty: q}, :long), do: Decimal.new(q)
  defp futures_qty(%_struct{short_qty: q}, :short), do: Decimal.new(q)

  defp futures_entry_price(%_struct{long_avg_cost: p}, :long), do: Decimal.new(p)
  defp futures_entry_price(%_struct{short_avg_cost: p}, :short), do: Decimal.new(p)

  @crossed [ExOkex.Futures.CrossedPosition, ExOkex.Swap.CrossedPosition]
  @fixed [ExOkex.Futures.FixedPosition, ExOkex.Swap.FixedPosition]
  defp margin_mode(%type{}) when type in @crossed, do: :crossed
  defp margin_mode(%type{}) when type in @fixed, do: :fixed

  defp leverage(venue_position), do: venue_position.leverage |> Decimal.new()
end
