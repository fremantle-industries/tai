defmodule Tai.Commander.Settings do
  @type settings :: Tai.Settings.t()

  @spec get :: settings
  def get do
    Tai.Settings.all()
  end
end
