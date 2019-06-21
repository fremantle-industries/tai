defmodule Tai.VenueAdapters.Mock do
  @behaviour Tai.Venues.Adapter
  import Tai.TestSupport.Mocks.Client
  alias Tai.Trading.OrderResponses

  def stream_supervisor, do: Tai.VenueAdapters.Mock.StreamSupervisor

  def order_book_feed, do: Tai.VenueAdapters.NullOrderBookFeed

  def products(venue_id) do
    with_mock_server(fn ->
      {:products, venue_id}
      |> Tai.TestSupport.Mocks.Server.eject()
      |> case do
        {:ok, products} -> {:ok, products}
        {:error, :not_found} -> {:error, :mock_response_not_found}
      end
    end)
  end

  def asset_balances(venue_id, account_id, _credentials) do
    with_mock_server(fn ->
      {venue_id, account_id}
      |> asset_balances_response_key()
      |> Tai.TestSupport.Mocks.Server.eject()
      |> case do
        {:ok, asset_balances} -> {:ok, asset_balances}
        {:error, :not_found} -> {:error, :mock_response_not_found}
      end
    end)
  end

  def maker_taker_fees(venue_id, account_id, _credentials) do
    with_mock_server(fn ->
      {venue_id, account_id}
      |> maker_taker_fees_response_key()
      |> Tai.TestSupport.Mocks.Server.eject()
      |> case do
        {:ok, fees} -> {:ok, fees}
        {:error, :not_found} -> {:error, :mock_response_not_found}
      end
    end)
  end

  def create_order(%Tai.Trading.Order{} = order, _credentials) do
    with_mock_server(fn ->
      match_attrs = %{
        symbol: order.product_symbol,
        price: order.price,
        size: order.qty,
        time_in_force: order.time_in_force
      }

      {:create_order, match_attrs}
      |> Tai.TestSupport.Mocks.Server.eject()
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
      |> Tai.TestSupport.Mocks.Server.eject()
      |> case do
        {:ok, {:raise, reason}} -> raise reason
        {:ok, _} = response -> response
        {:error, :not_found} -> {:error, :mock_not_found}
      end
    end)
  end

  def cancel_order(order, _credentials) do
    with_mock_server(fn ->
      {:cancel_order, order.venue_order_id}
      |> Tai.TestSupport.Mocks.Server.eject()
      |> case do
        {:ok, %OrderResponses.Cancel{}} = response -> response
        {:ok, %OrderResponses.CancelAccepted{}} = response -> response
        {:ok, {:raise, reason}} -> raise reason
        {:error, :not_found} -> {:error, :mock_not_found}
      end
    end)
  end

  def positions(_venue_id, _account_id, _credentials) do
    {:error, :not_supported}
  end

  def asset_balances_response_key({venue_id, account_id}),
    do: {__MODULE__, :asset_balances, venue_id, account_id}

  def maker_taker_fees_response_key({venue_id, account_id}),
    do: {__MODULE__, :maker_taker_fees, venue_id, account_id}
end
