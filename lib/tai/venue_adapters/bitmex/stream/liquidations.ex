defmodule Tai.VenueAdapters.Bitmex.Stream.Liquidations do
  def broadcast(
        %{
          "symbol" => exchange_symbol,
          "price" => price,
          "leavesQty" => leaves_qty,
          "side" => side,
          "orderID" => order_id
        },
        action,
        venue_id,
        received_at
      )
      when action == "insert" or action == "partial" do
    Tai.Events.broadcast(%Tai.Events.InsertLiquidation{
      venue_id: venue_id,
      # TODO: The list of products or a map of exchange symbol to symbol should be passed in
      symbol: exchange_symbol |> normalize_symbol,
      received_at: received_at,
      price: price,
      leaves_qty: leaves_qty,
      side: side |> normalize_side,
      order_id: order_id
    })
  end

  def broadcast(
        %{"symbol" => exchange_symbol, "orderID" => order_id, "leavesQty" => leaves_qty},
        action,
        venue_id,
        received_at
      )
      when action == "update" or action == "partial" do
    Tai.Events.broadcast(%Tai.Events.UpdateLiquidationLeavesQty{
      venue_id: venue_id,
      # TODO: The list of products or a map of exchange symbol to symbol should be passed in
      symbol: exchange_symbol |> normalize_symbol,
      received_at: received_at,
      leaves_qty: leaves_qty,
      order_id: order_id
    })
  end

  def broadcast(
        %{"symbol" => exchange_symbol, "orderID" => order_id, "price" => price},
        action,
        venue_id,
        received_at
      )
      when action == "update" or action == "partial" do
    Tai.Events.broadcast(%Tai.Events.UpdateLiquidationPrice{
      venue_id: venue_id,
      # TODO: The list of products or a map of exchange symbol to symbol should be passed in
      symbol: exchange_symbol |> normalize_symbol,
      received_at: received_at,
      price: price,
      order_id: order_id
    })
  end

  def broadcast(
        %{"symbol" => exchange_symbol, "orderID" => order_id},
        action,
        venue_id,
        received_at
      )
      when action == "delete" or action == "partial" do
    Tai.Events.broadcast(%Tai.Events.DeleteLiquidation{
      venue_id: venue_id,
      # TODO: The list of products or a map of exchange symbol to symbol should be passed in
      symbol: exchange_symbol |> normalize_symbol,
      received_at: received_at,
      order_id: order_id
    })
  end

  defp normalize_symbol(exchange_symbol) do
    exchange_symbol
    |> String.downcase()
    |> String.to_atom()
  end

  defp normalize_side("Buy"), do: :buy
  defp normalize_side("Sell"), do: :sell
end
