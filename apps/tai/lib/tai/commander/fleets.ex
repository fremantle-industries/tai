defmodule Tai.Commander.Fleets do
  def get(options) do
    Tai.Fleets.search(options)
  end
end
