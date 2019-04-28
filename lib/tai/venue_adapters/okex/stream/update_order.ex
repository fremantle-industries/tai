defmodule Tai.VenueAdapters.OkEx.Stream.UpdateOrder do
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
    result = Tai.Trading.OrderStore.passive_cancel(client_id, received_at, venue_timestamp)
    {client_id, :passive_cancel, result}
  end

  # TODO: For some reason swap seems to use status = 3 for open???
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
      when status == @pending or status == @submitting do
    {:ok, venue_timestamp} = Timex.parse(timestamp, @date_format)
    avg_price = price_avg |> Decimal.new()
    cumulative_qty = filled_qty |> Decimal.new()
    leaves_qty = size |> Decimal.new()

    result =
      Tai.Trading.OrderStore.open(
        client_id,
        venue_order_id,
        avg_price,
        cumulative_qty,
        leaves_qty,
        received_at,
        venue_timestamp
      )

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
      Tai.Trading.OrderStore.passive_partial_fill(
        client_id,
        avg_price,
        cumulative_qty,
        leaves_qty,
        received_at,
        venue_timestamp
      )

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
      Tai.Trading.OrderStore.passive_fill(
        client_id,
        cumulative_qty,
        received_at,
        venue_timestamp
      )

    {client_id, :passive_partial_fill, result}
  end

  # def update(_, %{"status" => status} = response, _) when status == @submitting do
  #   IO.puts("======== RESPONSE")
  #   IO.inspect(response)
  #   :ok
  # end
end
