defmodule Tai.Utils.String do
  @spec truncate(String.t(), pos_integer()) :: String.t()
  def truncate(str, len) do
    "#{str |> String.slice(0..(len - 1))}..."
  end
end
