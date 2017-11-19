defmodule Tai.Settings do
  def exchanges do
    Application.get_env(:tai, :exchanges)
  end

  def exchange_ids do
    exchanges()
    |> Enum.map(fn {id, _config} -> id end)
  end
end
