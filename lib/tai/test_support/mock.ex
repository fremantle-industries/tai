defmodule Tai.TestSupport.Mock do
  @type location :: Tai.Markets.Location.t()
  @type product :: Tai.Exchanges.Product.t()
  @type fee_info :: Tai.Exchanges.FeeInfo.t()

  @spec mock_product(product | map) :: :ok
  def mock_product(%Tai.Exchanges.Product{} = product) do
    product
    |> Tai.Exchanges.ProductStore.upsert()
  end

  def mock_product(attrs) when is_map(attrs) do
    Tai.Exchanges.Product
    |> struct(attrs)
    |> Tai.Exchanges.ProductStore.upsert()
  end

  @spec mock_fee_info(fee_info | map) :: :ok
  def mock_fee_info(%Tai.Exchanges.FeeInfo{} = fee_info) do
    fee_info
    |> Tai.Exchanges.FeeStore.upsert()
  end

  def mock_fee_info(attrs) when is_map(attrs) do
    Tai.Exchanges.FeeInfo
    |> struct(attrs)
    |> Tai.Exchanges.FeeStore.upsert()
  end

  @spec mock_asset_balance(
          exchange_id :: atom,
          account_id :: atom,
          asset :: atom,
          free :: number | Decimal.t() | String.t(),
          locked :: number | Decimal.t() | String.t()
        ) :: :ok
  def mock_asset_balance(exchange_id, account_id, asset, free, locked) do
    Tai.Exchanges.AssetBalances.upsert(%Tai.Exchanges.AssetBalance{
      exchange_id: exchange_id,
      account_id: account_id,
      asset: asset,
      free: Decimal.new(free),
      locked: Decimal.new(locked)
    })
  end

  @spec push_market_feed_snapshot(location :: location, bids :: map, asks :: map) ::
          :ok
          | {:error,
             %WebSockex.FrameEncodeError{}
             | %WebSockex.ConnError{}
             | %WebSockex.NotConnectedError{}
             | %WebSockex.InvalidFrameError{}}
  def push_market_feed_snapshot(location, bids, asks) do
    :ok =
      location.venue_id
      |> whereis_market_data_feed
      |> send_json_msg(%{
        type: :snapshot,
        symbol: location.product_symbol,
        bids: bids,
        asks: asks
      })
  end

  defp whereis_market_data_feed(venue_id) do
    venue_id
    |> Tai.Exchanges.OrderBookFeed.to_name()
    |> Process.whereis()
  end

  defp send_json_msg(pid, msg) do
    Tai.WebSocket.send_json_msg(pid, msg)
  end
end
