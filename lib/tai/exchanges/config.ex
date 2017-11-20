defmodule Tai.Exchanges.Config do
  def all do
    Application.get_env(:tai, :exchanges)
  end

  def adapter(name) do
    all()
    |> Map.fetch!(name)
  end
end
