defmodule Tai.VenueAdapters.Bitmex.Stream.UpdateAccount do
  alias Tai.VenueAdapters.Bitmex.NormalizeAccount

  def apply(%{"marginBalance" => margin} = data, _received_at, state) do
    process_with_margin(data, margin, state)
  end

  def apply(%{"availableMargin" => margin} = data, _received_at, state) do
    process_with_margin(data, margin, state)
  end

  def apply(_data, _received_at, _state) do
    :ok
  end

  defp process_with_margin(data, margin, state) do
    currency = Map.fetch!(data, "currency")
    equity = NormalizeAccount.satoshis_to_btc(margin)

    with {:ok, key} <- build_key(currency, state),
         {:ok, account} <- Tai.Venues.AccountStore.find(key) do
      account = %{account | equity: equity, locked: equity}
      {:ok, _} = Tai.Venues.AccountStore.put(account)
      :ok
    else
      {:error, :not_found} = error -> error
      {:error, :unknown_asset} = error -> error
    end
  end

  defp build_key("XBt", state) do
    key = {state.venue, state.credential_id, :btc, "default"}
    {:ok, key}
  end

  defp build_key(_currency, _state) do
    {:error, :unknown_asset}
  end
end
