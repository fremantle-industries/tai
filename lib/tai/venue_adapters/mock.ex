defmodule Tai.VenueAdapters.Mock do
  use Tai.Venues.Adapter
  import Tai.TestSupport.Mocks.Client

  def stream_supervisor, do: Tai.Venues.NullStreamSupervisor

  def order_book_feed, do: Tai.VenueAdapters.Mock.OrderBookFeed

  def products(venue_id) do
    with_mock_server(fn ->
      venue_id
      |> products_response_key()
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

  def create_order(%Tai.Trading.Order{} = _order, _credentials) do
    {:error, :not_implemented}
  end

  def products_response_key(venue_id), do: {__MODULE__, :products, venue_id}

  def asset_balances_response_key({venue_id, account_id}),
    do: {__MODULE__, :asset_balances, venue_id, account_id}

  def maker_taker_fees_response_key({venue_id, account_id}),
    do: {__MODULE__, :maker_taker_fees, venue_id, account_id}
end
