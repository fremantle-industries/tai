defmodule Tai.TestSupport.Mock do
  @spec mock_product(Tai.Exchanges.Product.t() | map) :: :ok
  def mock_product(%Tai.Exchanges.Product{} = product) do
    product
    |> Tai.Exchanges.Products.upsert()
  end

  def mock_product(%{} = attrs) do
    Tai.Exchanges.Product
    |> struct(attrs)
    |> Tai.Exchanges.Products.upsert()
  end

  @spec mock_fee_info(Tai.Exchanges.FeeInfo.t() | map) :: :ok
  def mock_fee_info(%Tai.Exchanges.FeeInfo{} = fee_info) do
    fee_info
    |> Tai.Exchanges.Fees.upsert()
  end

  def mock_fee_info(%{} = attrs) do
    Tai.Exchanges.FeeInfo
    |> struct(attrs)
    |> Tai.Exchanges.Fees.upsert()
  end

  @spec mock_snapshot(atom, atom, map, map) ::
          :ok
          | {:error,
             %WebSockex.FrameEncodeError{}
             | %WebSockex.ConnError{}
             | %WebSockex.NotConnectedError{}
             | %WebSockex.InvalidFrameError{}}
  def mock_snapshot(feed_id, symbol, bids, asks) do
    feed_pid =
      feed_id
      |> Tai.Exchanges.OrderBookFeed.to_name()
      |> Process.whereis()

    :ok =
      Tai.WebSocket.send_json_msg(feed_pid, %{
        type: :snapshot,
        symbol: symbol,
        bids: bids,
        asks: asks
      })
  end
end
