defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdatePosition do
  alias __MODULE__
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  @type t :: %UpdatePosition{data: map}

  @enforce_keys ~w(data)a
  defstruct ~w(data)a

  defimpl ProcessAuth.Message do
    def process(
          %UpdatePosition{data: %{"symbol" => venue_symbol, "currentQty" => venue_qty}},
          _received_at,
          state
        ) do
      with {:ok, key} <- build_key(venue_symbol, state),
           {:ok, position} <- Tai.Trading.PositionStore.find(key) do
        position =
          position
          |> Map.put(:qty, Decimal.new(venue_qty))

        {:ok, _} = Tai.Trading.PositionStore.put(position)
        :ok
      else
        {:error, :not_found} = error -> error
      end

      :ok
    end

    defp build_key(venue_symbol, state) do
      symbol = Tai.VenueAdapters.Bitmex.Product.downcase_and_atom(venue_symbol)
      key = {state.venue, state.credential_id, symbol}
      {:ok, key}
    end
  end
end
