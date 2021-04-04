defmodule Tai.VenueAdapters.OkEx.Stream.UpdateOrder do
  alias Tai.Trading.OrderStore

  @canceled "-1"
  @pending "0"
  @partially_filled "1"
  @fully_filled "2"
  @submitting "3"

  @date_format "{ISO:Extended:Z}"

  def update(
        client_id,
        %{"state" => state, "timestamp" => timestamp},
        received_at,
        _state
      )
      when state == @canceled do
    {:ok, venue_timestamp} = Timex.parse(timestamp, @date_format)

    %OrderStore.Actions.PassiveCancel{
      client_id: client_id,
      last_received_at: received_at,
      last_venue_timestamp: venue_timestamp
    }
    |> OrderStore.update()
    |> notify()
  end

  def update(
        client_id,
        %{
          "state" => state,
          "order_id" => venue_order_id,
          "timestamp" => timestamp
        },
        received_at,
        _state
      )
      when state == @submitting do
    {:ok, venue_timestamp} = Timex.parse(timestamp, @date_format)

    %OrderStore.Actions.AcceptCreate{
      client_id: client_id,
      venue_order_id: venue_order_id,
      last_received_at: received_at,
      last_venue_timestamp: venue_timestamp
    }
    |> OrderStore.update()
    |> notify()
  end

  def update(
        client_id,
        %{
          "state" => state,
          "order_id" => venue_order_id,
          "timestamp" => timestamp,
          "size" => size
        } = msg,
        received_at,
        _state
      )
      when state == @pending do
    filled_qty = Map.get(msg, "filled_size") || Map.fetch!(msg, "filled_qty")
    {:ok, venue_timestamp} = Timex.parse(timestamp, @date_format)
    cumulative_qty = filled_qty |> Decimal.new()
    leaves_qty = size |> Decimal.new() |> Decimal.sub(cumulative_qty)

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
        client_id,
        %{
          "state" => state,
          "timestamp" => timestamp,
          "size" => size
        } = msg,
        received_at,
        _state
      )
      when state == @partially_filled do
    filled_qty = Map.get(msg, "filled_size") || Map.fetch!(msg, "filled_qty")
    {:ok, venue_timestamp} = Timex.parse(timestamp, @date_format)
    cumulative_qty = filled_qty |> Decimal.new()
    leaves_qty = size |> Decimal.new() |> Decimal.sub(cumulative_qty)

    %OrderStore.Actions.PassivePartialFill{
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
        client_id,
        %{
          "state" => state,
          "timestamp" => timestamp
        } = msg,
        received_at,
        _state
      )
      when state == @fully_filled do
    filled_qty = Map.get(msg, "filled_size") || Map.fetch!(msg, "filled_qty")
    {:ok, venue_timestamp} = Timex.parse(timestamp, @date_format)
    cumulative_qty = filled_qty |> Decimal.new()

    %OrderStore.Actions.PassiveFill{
      client_id: client_id,
      cumulative_qty: cumulative_qty,
      last_received_at: received_at,
      last_venue_timestamp: venue_timestamp
    }
    |> OrderStore.update()
    |> notify()
  end

  def update(_client_id, msg, received_at, state) do
    TaiEvents.warn(%Tai.Events.StreamMessageUnhandled{
      venue_id: state.venue,
      msg: msg,
      received_at: received_at |> Tai.Time.monotonic_to_date_time!()
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
