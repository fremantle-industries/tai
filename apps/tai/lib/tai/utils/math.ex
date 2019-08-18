defmodule Tai.Utils.Math do
  @doc """
  We need to define our own custom pow function to handle large numbers

  https://awochna.com/2017/04/02/elixir-math.html
  """
  def pow(base, 1), do: base
  def pow(base, exp), do: base * pow(base, exp - 1)
end
