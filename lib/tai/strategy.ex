defmodule Tai.Strategy do
  def info(name) do
    name
    |> to_pid
    |> GenServer.call(:info)
    |> case do
      %DateTime{} = started_at ->
        {:ok, %{started_at: started_at}}
    end
  end

  def to_pid(name), do: "strategy_#{name}" |> String.to_atom
end
