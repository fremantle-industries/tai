defmodule Tai.Advisor do
  def info(advisor_id) do
    advisor_id
    |> to_name
    |> GenServer.call(:info)
    |> case do
      %DateTime{} = started_at ->
        {:ok, %{started_at: started_at}}
    end
  end

  def to_name(advisor_id), do: :"advisor_#{advisor_id}"
end
