defmodule Tai.WebSocket do
  @type errors ::
          %WebSockex.FrameEncodeError{}
          | %WebSockex.ConnError{}
          | %WebSockex.NotConnectedError{}
          | %WebSockex.InvalidFrameError{}

  @spec send_msg(pid, binary) :: :ok | {:error, errors}
  def send_msg(pid, msg), do: WebSockex.send_frame(pid, {:text, msg})

  @spec send_json_msg(pid, map) :: :ok | {:error, errors}
  def send_json_msg(pid, msg), do: send_msg(pid, msg |> Jason.encode!())
end
