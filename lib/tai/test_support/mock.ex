defmodule Tai.TestSupport.Mock do
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

  @spec reset_mocks :: no_return
  def reset_mocks do
    Application.stop(:tai)
    :ok = Application.start(:tai)
  end
end
