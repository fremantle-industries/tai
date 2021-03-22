defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateAccount do
  alias __MODULE__
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth
  alias Tai.VenueAdapters.Bitmex.NormalizeAccount

  @type t :: %UpdateAccount{data: map}

  @enforce_keys ~w(data)a
  defstruct ~w(data)a

  defimpl ProcessAuth.Message do
    def process(%UpdateAccount{data: %{"marginBalance" => margin} = data}, _received_at, state),
      do: process_with_margin(data, margin, state)

    def process(%UpdateAccount{data: %{"availableMargin" => margin} = data}, _received_at, state),
      do: process_with_margin(data, margin, state)

    def process(_update_account, _received_at, _state), do: :ok

    defp process_with_margin(data, margin, state) do
      currency = Map.fetch!(data, "currency")
      equity = NormalizeAccount.satoshis_to_btc(margin)

      with {:ok, key} <- build_key(currency, state),
           {:ok, account} <- Tai.Venues.AccountStore.find(key) do
        account =
          account
          |> Map.put(:equity, equity)
          |> Map.put(:locked, equity)

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
end
