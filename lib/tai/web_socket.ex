defmodule Tai.WebSocket do
  def send_msg(pid, msg) do
    WebSockex.send_frame(pid, {:text, msg})
  end

  @spec send_json_msg(pid, map) :: :ok | {:error, atom}
  def send_json_msg(pid, msg) do
    send_msg(pid, msg |> Poison.encode!())
  end
end
