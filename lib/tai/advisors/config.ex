defmodule Tai.Advisors.Config do
  def all(advisors \\ Application.get_env(:tai, :advisors)) do
    advisors || %{}
  end
end
