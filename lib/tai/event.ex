defmodule Tai.Event do
  @type t ::
          Tai.Events.AddFreeAssetBalance.t()
          | Tai.Events.HydrateProducts.t()
          | Tai.Events.LockAssetBalanceInsufficientFunds.t()
          | Tai.Events.LockAssetBalanceOk.t()
          | Tai.Events.OrderBookSnapshot.t()
          | Tai.Events.SubFreeAssetBalance.t()
          | Tai.Events.UnlockAssetBalanceInsufficientFunds.t()
          | Tai.Events.UnlockAssetBalanceOk.t()
          | Tai.Events.UpsertAssetBalance.t()
          | map

  @spec encode!(event :: t) :: iodata | no_return
  def encode!(event) when is_map(event) do
    %{
      type: event |> extract_type,
      data: event |> Tai.LogEvent.to_data()
    }
    |> Poison.encode!()
  end

  defp extract_type(event) do
    event
    |> Map.fetch!(:__struct__)
    |> Atom.to_string()
    |> String.replace("Elixir.", "")
    |> String.replace("Tai.Events.", "Tai.")
  end
end
