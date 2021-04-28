defmodule Tai.DateTime do
  @spec timestamp(Calendar.calendar()) :: DateTime.t()
  def timestamp(calendar \\ Calendar.ISO) do
    DateTime.utc_now(calendar)
  end

  @spec min(DateTime.t(), DateTime.t()) :: DateTime.t()
  def min(a, b) do
    [a, b] |> Enum.sort({:asc, DateTime}) |> List.first()
  end

  @spec max(DateTime.t(), DateTime.t()) :: DateTime.t()
  def max(a, b) do
    [a, b] |> Enum.sort({:desc, DateTime}) |> List.first()
  end
end
