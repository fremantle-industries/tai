defmodule Tai.WebSocket do
  @spec send_msg(pid, binary) ::
          :ok
          | {:error,
             %WebSockex.FrameEncodeError{}
             | %WebSockex.ConnError{}
             | %WebSockex.NotConnectedError{}
             | %WebSockex.InvalidFrameError{}}
  def send_msg(pid, msg) do
    WebSockex.send_frame(pid, {:text, msg})
  end

  @spec send_json_msg(pid, map) ::
          :ok
          | {:error,
             %WebSockex.FrameEncodeError{}
             | %WebSockex.ConnError{}
             | %WebSockex.NotConnectedError{}
             | %WebSockex.InvalidFrameError{}}
  def(send_json_msg(pid, msg)) do
    send_msg(pid, msg |> Poison.encode!())
  end
end
