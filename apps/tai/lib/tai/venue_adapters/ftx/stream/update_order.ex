defmodule Tai.VenueAdapters.Ftx.Stream.UpdateOrder do
  alias Tai.Orders.{OrderStore, Transitions}

  @date_format "{ISO:Extended}"

  def update(%{"clientId" => nil} = venue_order, received_at, state) do
    TaiEvents.warn(%Tai.Events.StreamMessageUnhandled{
      venue_id: state.venue,
      msg: venue_order,
      received_at: received_at |> Tai.Time.monotonic_to_date_time!()
    })
  end

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

    %Transitions.Open{
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
      )
      when filled_size != size do
    {:ok, venue_timestamp} = Timex.parse(created_at, @date_format)

    %Transitions.PassiveCancel{
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

    %Transitions.PassivePartialFill{
      client_id: client_id,
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
      )
      when filled_size == size do
    {:ok, venue_timestamp} = Timex.parse(created_at, @date_format)
    cumulative_qty = filled_size |> Tai.Utils.Decimal.cast!()

    %Transitions.PassiveFill{
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
      received_at: received_at |> Tai.Time.monotonic_to_date_time!()
    })
  end

  defp notify({:ok, {old, updated}}) do
    Tai.Orders.Services.NotifyUpdate.notify!(old, updated)
  end

  defp notify({:error, {:invalid_status, was, required, %transition_name{} = transition}}) do
    TaiEvents.warn(%Tai.Events.OrderUpdateInvalidStatus{
      was: was,
      required: required,
      client_id: transition.client_id,
      transition: transition_name
    })
  end

  defp notify({:error, {:not_found, %transition_name{} = transition}}) do
    TaiEvents.warn(%Tai.Events.OrderUpdateNotFound{
      client_id: transition.client_id,
      transition: transition_name
    })
  end
end
