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
        %{"status" => status, "timestamp" => timestamp},
        received_at
      )
      when status == @canceled do
    {:ok, venue_timestamp} = Timex.parse(timestamp, @date_format)

    %OrderStore.Actions.PassiveCancel{
      client_id: client_id,
      last_received_at: received_at,
      last_venue_timestamp: venue_timestamp
    }
    |> OrderStore.update()
  end

  def update(
        client_id,
        %{
          "status" => status,
          "order_id" => venue_order_id,
          "timestamp" => timestamp
        },
        received_at
      )
      when status == @submitting do
    {:ok, venue_timestamp} = Timex.parse(timestamp, @date_format)

    %OrderStore.Actions.AcceptCreate{
      client_id: client_id,
      venue_order_id: venue_order_id,
      last_received_at: received_at,
      last_venue_timestamp: venue_timestamp
    }
    |> OrderStore.update()
  end

  def update(
        client_id,
        %{
          "status" => status,
          "order_id" => venue_order_id,
          "filled_qty" => filled_qty,
          "timestamp" => timestamp,
          "size" => size
        },
        received_at
      )
      when status == @pending do
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
  end

  def update(
        client_id,
        %{
          "status" => status,
          "filled_qty" => filled_qty,
          "timestamp" => timestamp,
          "size" => size
        },
        received_at
      )
      when status == @partially_filled do
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
  end

  def update(
        client_id,
        %{
          "status" => status,
          "filled_qty" => filled_qty,
          "timestamp" => timestamp
        },
        received_at
      )
      when status == @fully_filled do
    {:ok, venue_timestamp} = Timex.parse(timestamp, @date_format)
    cumulative_qty = filled_qty |> Decimal.new()

    %OrderStore.Actions.PassiveFill{
      client_id: client_id,
      cumulative_qty: cumulative_qty,
      last_received_at: received_at,
      last_venue_timestamp: venue_timestamp
    }
    |> OrderStore.update()
  end
end
