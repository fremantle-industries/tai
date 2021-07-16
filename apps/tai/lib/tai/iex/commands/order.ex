defmodule Tai.IEx.Commands.Order do
  @moduledoc """
  Display the list of order transitions and their details
  """

  import Tai.IEx.Commands.Table, only: [render!: 2]

  @type client_id :: Tai.Orders.Order.client_id()

  @header [
    "Attribute",
    "Value",
  ]

  @show_attributes ~w[
    client_id
    venue_order_id
    status
    product_symbol
    venue_product_symbol
    side
    price
    qty
    leaves_qty
    cumulative_qty
    post_only
    close
  ]a

  @spec order(client_id) :: no_return
  def order(client_id) do
    client_id
    |> Tai.Commander.get_order_by_client_id()
    |> case do
      nil ->
        []

      order ->
        @show_attributes
        |> Enum.map(fn a -> {a, Map.get(order, a)} end)
        |> Enum.map(fn {k, v} -> [k, v |> value()] end)
    end
    |> render!(@header)
  end

  defp value(v) when is_bitstring(v) or is_atom(v), do: v
  defp value(%Decimal{} = v), do: Decimal.to_string(v, :normal)
  defp value(v), do: inspect(v)
end
