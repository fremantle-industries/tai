defmodule Tai.Event do
  @type t :: struct

  @spec encode!(t) :: iodata | no_return
  def encode!(event) when is_map(event) do
    %{
      type: event |> extract_type,
      data: event |> Tai.LogEvent.to_data()
    }
    |> Jason.encode!()
  end

  defp extract_type(event) do
    event
    |> Map.fetch!(:__struct__)
    |> Atom.to_string()
    |> String.replace("Elixir.", "")
    |> String.replace("Tai.Events.", "Tai.")
  end
end
