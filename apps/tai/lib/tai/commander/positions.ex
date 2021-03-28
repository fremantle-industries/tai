defmodule Tai.Commander.Positions do
  @type position :: Tai.Trading.Position.t()

  @spec get :: [position]
  def get do
    Tai.Trading.PositionStore.all()
  end
end
