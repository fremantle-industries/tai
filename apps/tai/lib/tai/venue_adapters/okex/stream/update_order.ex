defmodule Tai.VenueAdapters.OkEx.Stream.UpdateOrder do
  alias Tai.Trading.OrderStore

  @cancelled "-1"
  @pending "0"
  @partially_filled "1"
  @fully_filled "2"
  @submitting "3"

  @date_format "{ISO:Extended}"

  def update(
        client_id,
        %{"status" => status, "timestamp" => timestamp},
        received_at
      )
      when status == @cancelled do
    {:ok, venue_timestamp} = Timex.parse(timestamp, @date_format)

    result =
      %OrderStore.Actions.PassiveCancel{
        client_id: client_id,
        last_received_at: received_at,
        last_venue_timestamp: venue_timestamp
      }
      |> OrderStore.update()

    {client_id, :passive_cancel, result}
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

    result =
      %OrderStore.Actions.AcceptCreate{
        client_id: client_id,
        venue_order_id: venue_order_id,
        last_received_at: received_at,
        last_venue_timestamp: venue_timestamp
      }
      |> OrderStore.update()

    {client_id, :accept_create, result}
  end

  def update(
        client_id,
        %{
          "status" => status,
          "order_id" => venue_order_id,
          "price_avg" => price_avg,
          "filled_qty" => filled_qty,
          "timestamp" => timestamp,
          "size" => size
        },
        received_at
      )
      when status == @pending do
    {:ok, venue_timestamp} = Timex.parse(timestamp, @date_format)
    avg_price = price_avg |> Decimal.new()
    cumulative_qty = filled_qty |> Decimal.new()
    leaves_qty = size |> Decimal.new()

    result =
      %OrderStore.Actions.Open{
        client_id: client_id,
        venue_order_id: venue_order_id,
        avg_price: avg_price,
        cumulative_qty: cumulative_qty,
        leaves_qty: leaves_qty,
        last_received_at: received_at,
        last_venue_timestamp: venue_timestamp
      }
      |> OrderStore.update()

    {client_id, :open, result}
  end

  def update(
        client_id,
        %{
          "status" => status,
          "price_avg" => price_avg,
          "filled_qty" => filled_qty,
          "timestamp" => timestamp,
          "size" => size
        },
        received_at
      )
      when status == @partially_filled do
    {:ok, venue_timestamp} = Timex.parse(timestamp, @date_format)
    avg_price = price_avg |> Decimal.new()
    cumulative_qty = filled_qty |> Decimal.new()
    leaves_qty = size |> Decimal.new()

    result =
      %OrderStore.Actions.PassivePartialFill{
        client_id: client_id,
        avg_price: avg_price,
        cumulative_qty: cumulative_qty,
        leaves_qty: leaves_qty,
        last_received_at: received_at,
        last_venue_timestamp: venue_timestamp
      }
      |> OrderStore.update()

    {client_id, :passive_partial_fill, result}
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

    result =
      %OrderStore.Actions.PassiveFill{
        client_id: client_id,
        cumulative_qty: cumulative_qty,
        last_received_at: received_at,
        last_venue_timestamp: venue_timestamp
      }
      |> OrderStore.update()

    {client_id, :passive_partial_fill, result}
  end
end
