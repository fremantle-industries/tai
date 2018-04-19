defmodule Tai.Advisors.Config do
  def all(advisors \\ Application.get_env(:tai, :advisors)) do
    advisors || %{}
  end

  def servers do
    all()
    |> Enum.map(fn {advisor_id, config} ->
      {advisor_id, Keyword.get(config, :server)}
    end)
  end

  def order_books(advisor_id) do
    all()
    |> Map.get(advisor_id, [])
    |> Keyword.get(:order_books)
  end

  def exchanges(advisor_id) do
    all()
    |> Map.get(advisor_id, [])
    |> Keyword.get(:exchanges, [])
  end
end
