defmodule Tai.ExchangeAdapters.Gdax.Account.Orders do
  @moduledoc """
  Create buy and sell orders for the GDAX adapter
  """

  alias Tai.ExchangeAdapters.Gdax.Product

  def create(order, credentials) do
    venue_type = order.type |> Atom.to_string()
    venue_side = order.side |> Atom.to_string()
    venue_product_id = Product.to_product_id(order.symbol)

    # TODO: this should include time in force
    %{
      "type" => venue_type,
      "side" => venue_side,
      "product_id" => venue_product_id,
      "price" => order.price,
      "size" => order.size
    }
    |> ExGdax.create_order(credentials)
    |> parse_response(order.time_in_force)
  end

  defp parse_response(
         {
           :ok,
           %{
             "id" => venue_order_id,
             "status" => venue_status,
             "size" => size,
             "filled_size" => filled_size
           }
         },
         time_in_force
       ) do
    response = %Tai.Trading.OrderResponse{
      id: venue_order_id,
      status: from_venue_status(venue_status),
      time_in_force: time_in_force,
      original_size: Decimal.new(size),
      cumulative_qty: Decimal.new(filled_size)
    }

    {:ok, response}
  end

  defp parse_response({:error, "Insufficient funds" = reason, _status_code}, _time_in_force) do
    {:error, %Tai.Trading.InsufficientBalanceError{reason: reason}}
  end

  defp parse_response({:error, reason, _status_code}, _time_in_force) do
    {:error, reason}
  end

  defp from_venue_status("open"), do: :open
  defp from_venue_status("pending"), do: :pending
end
