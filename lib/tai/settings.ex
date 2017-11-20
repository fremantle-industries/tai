defmodule Tai.Settings do
  def exchange_ids do
    Tai.Exchanges.Config.all
    |> Enum.map(fn {id, _config} -> id end)
  end
end
