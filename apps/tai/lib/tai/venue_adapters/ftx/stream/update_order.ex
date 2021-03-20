defmodule Tai.VenueAdapters.Ftx.Stream.UpdateOrder do
  alias Tai.Trading.OrderStore

  @date_format "{ISO:Extended}"

  def update(%{"client_id" => nil}, _received_at, _state), do: :ok

  def update(
        %{
          "status" => "new",
          "clientId" => client_id,
          "id" => venue_order_id,
          "createdAt" => created_at,
          "filledSize" => filled_size,
          "remainingSize" => remaining_size
        },
        received_at,
        _state
      ) do
    {:ok, venue_timestamp} = Timex.parse(created_at, @date_format)
    cumulative_qty = filled_size |> Tai.Utils.Decimal.cast!()
    leaves_qty = remaining_size |> Tai.Utils.Decimal.cast!()

    %OrderStore.Actions.Open{
      client_id: client_id,
      venue_order_id: venue_order_id,
      cumulative_qty: cumulative_qty,
      leaves_qty: leaves_qty,
      last_received_at: received_at,
      last_venue_timestamp: venue_timestamp
    }
    |> OrderStore.update()
    |> notify()
  end

  def update(
        %{
          "status" => "closed",
          "clientId" => client_id,
          "createdAt" => created_at,
          "filledSize" => filled_size,
          "size" => size
        },
        received_at,
        _state
  ) when filled_size != size do
    {:ok, venue_timestamp} = Timex.parse(created_at, @date_format)

    %OrderStore.Actions.PassiveCancel{
      client_id: client_id,
      last_received_at: received_at,
      last_venue_timestamp: venue_timestamp
    }
    |> OrderStore.update()
    |> notify()
  end

  def update(
        %{
          "status" => "open",
          "clientId" => client_id,
          "id" => venue_order_id,
          "createdAt" => created_at,
          "filledSize" => filled_size,
          "remainingSize" => remaining_size
        },
        received_at,
        _state
  ) do
    {:ok, venue_timestamp} = Timex.parse(created_at, @date_format)
    cumulative_qty = filled_size |> Tai.Utils.Decimal.cast!()
    leaves_qty = remaining_size |> Tai.Utils.Decimal.cast!()

    %OrderStore.Actions.Open{
      client_id: client_id,
      venue_order_id: venue_order_id,
      cumulative_qty: cumulative_qty,
      leaves_qty: leaves_qty,
      last_received_at: received_at,
      last_venue_timestamp: venue_timestamp
    }
    |> OrderStore.update()
    |> notify()
  end

  def update(
        %{
          "status" => "closed",
          "clientId" => client_id,
          "createdAt" => created_at,
          "filledSize" => filled_size,
          "size" => size
        },
        received_at,
        _state
      ) when filled_size == size  do
    {:ok, venue_timestamp} = Timex.parse(created_at, @date_format)
    cumulative_qty = filled_size |> Tai.Utils.Decimal.cast!()

    %OrderStore.Actions.PassiveFill{
      client_id: client_id,
      cumulative_qty: cumulative_qty,
      last_received_at: received_at,
      last_venue_timestamp: venue_timestamp
    }
    |> OrderStore.update()
    |> notify()
  end

  def update(venue_order, received_at, state) do
    TaiEvents.warn(%Tai.Events.StreamMessageUnhandled{
      venue_id: state.venue,
      msg: venue_order,
      received_at: received_at
    })
  end

  defp notify({:ok, {old, updated}}) do
    Tai.Trading.NotifyOrderUpdate.notify!(old, updated)
  end

  defp notify({:error, {:invalid_status, was, required, %action_name{} = action}}) do
    TaiEvents.warn(%Tai.Events.OrderUpdateInvalidStatus{
      was: was,
      required: required,
      client_id: action.client_id,
      action: action_name
    })
  end

  defp notify({:error, {:not_found, %action_name{} = action}}) do
    TaiEvents.warn(%Tai.Events.OrderUpdateNotFound{
      client_id: action.client_id,
      action: action_name
    })
  end
end
