defmodule Tai.TestSupport.Mocks.Client do
  def with_mock_server(func) do
    try do
      func.()
    catch
      :exit, {:noproc, {GenServer, :call, [Tai.TestSupport.Mocks.Server, _, _]}} ->
        {:error, :mock_server_not_started}
    end
  end
end
