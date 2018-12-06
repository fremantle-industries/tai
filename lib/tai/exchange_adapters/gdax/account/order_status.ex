defmodule Tai.ExchangeAdapters.Gdax.Account.OrderStatus do
  def fetch(order_id, credentials) do
    order_id
    |> ExGdax.get_order(credentials)
    |> parse_response
  end

  defp parse_response({:ok, %{"status" => venue_status}}) do
    status = venue_status |> from_venue_status
    {:ok, status}
  end

  defp parse_response({:error, message, _status_code}) do
    {:error, message}
  end

  def from_venue_status("pending"), do: :pending
  def from_venue_status("open"), do: :open
end
