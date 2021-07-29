defmodule Tai.VenueAdapters.Mock do
  import Tai.TestSupport.Mocks.Client
  alias Tai.Orders.Responses
  alias Tai.TestSupport.Mocks

  @behaviour Tai.Venues.Adapter

  def stream_supervisor, do: Tai.VenueAdapters.Mock.StreamSupervisor

  def products(venue_id) do
    with_mock_server(fn ->
      {:products, venue_id}
      |> Mocks.Server.eject()
      |> case do
        {:ok, products} -> {:ok, products}
        {:error, :not_found} -> {:error, :mock_response_not_found}
      end
    end)
  end

  def accounts(venue_id, credential_id, _credentials) do
    with_mock_server(fn ->
      {:accounts, venue_id, credential_id}
      |> Mocks.Server.eject()
      |> case do
        {:ok, accounts} -> {:ok, accounts}
        {:error, :not_found} -> {:error, :mock_response_not_found}
      end
    end)
  end

  def maker_taker_fees(venue_id, credential_id, _credentials) do
    with_mock_server(fn ->
      {:maker_taker_fees, venue_id, credential_id}
      |> Mocks.Server.eject()
      |> case do
        {:ok, fees} -> {:ok, fees}
        {:error, :not_found} -> {:error, :mock_response_not_found}
      end
    end)
  end

  def create_order(order, _credentials) do
    with_mock_server(fn ->
      match_attrs = %{
        symbol: order.product_symbol,
        price: order.price,
        size: order.qty,
        time_in_force: order.time_in_force
      }

      {:create_order, match_attrs}
      |> Mocks.Server.eject()
      |> case do
        {:ok, {:raise, reason}} -> raise reason
        {:ok, _response} = result -> result
        {:error, :not_found} -> {:error, :mock_not_found}
      end
    end)
  end

  def amend_order(order, attrs, _credentials) do
    with_mock_server(fn ->
      match_attrs = Map.merge(attrs, %{venue_order_id: order.venue_order_id})

      {:amend_order, match_attrs}
      |> Mocks.Server.eject()
      |> case do
        {:ok, %Responses.AmendAccepted{}} = response -> response
        {:ok, {:raise, reason}} -> raise reason
        {:error, :not_found} -> {:error, :mock_not_found}
      end
    end)
  end

  def amend_bulk_orders(amend_set, _credentials) do
    match_attrs =
      Enum.map(amend_set, fn {o, a} -> Map.merge(a, %{venue_order_id: o.venue_order_id}) end)

    with_mock_server(fn ->
      {:amend_bulk_orders, match_attrs}
      |> Mocks.Server.eject()
      |> case do
        {:ok, %Responses.AmendBulk{}} = response -> response
        {:ok, {:raise, reason}} -> raise reason
        {:error, :not_found} -> {:error, :mock_not_found}
      end
    end)
  end

  def cancel_order(order, _credentials) do
    with_mock_server(fn ->
      {:cancel_order, order.venue_order_id}
      |> Mocks.Server.eject()
      |> case do
        {:ok, %Responses.CancelAccepted{}} = response -> response
        {:ok, {:raise, reason}} -> raise reason
        {:error, :not_found} -> {:error, :mock_not_found}
      end
    end)
  end

  def positions(_venue_id, _credential_id, _credentials) do
    {:error, :not_supported}
  end
end
