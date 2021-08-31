defmodule Tai.Fleets do
  alias __MODULE__

  @spec load :: Fleets.Services.Load.result()
  @spec load(map) :: Fleets.Services.Load.result()
  def load(config \\ Tai.Config.get(:fleets)) do
    Fleets.Services.Load.execute(config)
  end

  @spec search(list) :: Fleets.Queries.Search.result()
  def search(options) do
    Fleets.Queries.Search.call(options)
  end
end
