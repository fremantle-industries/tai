defmodule Tai.Strategy do
  def info(strategy_id) do
    strategy_id
    |> to_name
    |> GenServer.call(:info)
    |> case do
      %DateTime{} = started_at ->
        {:ok, %{started_at: started_at}}
    end
  end

  def to_name(strategy_id), do: :"strategy_#{strategy_id}"
end
