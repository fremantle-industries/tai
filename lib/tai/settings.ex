defmodule Tai.Settings do
  def accounts do
    Application.get_env(:tai, :accounts)
  end

  def account_ids do
    accounts()
    |> Enum.map(fn {id, _config} -> id end)
  end
end
