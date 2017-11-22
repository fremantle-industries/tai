defmodule Tai.Strategies.Config do
  def all(strategies \\ Application.get_env(:tai, :strategies)) do
    strategies || %{}
  end
end
