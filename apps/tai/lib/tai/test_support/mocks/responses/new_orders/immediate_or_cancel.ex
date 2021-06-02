defmodule Tai.TestSupport.Mocks.Responses.NewOrders.ImmediateOrCancel do
  alias Tai.TestSupport.Mocks
  alias Tai.NewOrders.{Order, Responses, Submissions}

  @type buy_limit :: Submissions.BuyLimitIoc.t()
  @type sell_limit :: Submissions.SellLimitIoc.t()
  @type submission :: buy_limit | sell_limit
  @type venue_order_id :: Order.venue_order_id()
  @type insert_result :: :ok

  @spec expired(submission) :: insert_result
  def expired(submission), do: expired(Ecto.UUID.generate(), submission)

  @spec expired(venue_order_id, submission) :: insert_result
  def expired(venue_order_id, submission) do
    expired(venue_order_id, submission, %{})
  end

  @spec expired(venue_order_id, submission, map) :: insert_result
  def expired(venue_order_id, submission, attrs) do
    qty = submission.qty
    cumulative_qty = attrs |> Map.get(:cumulative_qty, Decimal.new(0))

    order_response = %Responses.Create{
      id: venue_order_id,
      status: :expired,
      original_size: qty,
      cumulative_qty: cumulative_qty,
      leaves_qty: Decimal.new(0),
      venue_timestamp: Timex.now(),
      received_at: Tai.Time.monotonic_time()
    }

    match_attrs = %{
      symbol: submission.product_symbol,
      price: submission.price,
      size: qty,
      time_in_force: :ioc
    }

    {:create_order, match_attrs}
    |> Mocks.Server.insert(order_response)
  end

  @spec filled(submission) :: insert_result
  def filled(submission), do: filled(Ecto.UUID.generate(), submission)

  @spec filled(venue_order_id, submission) :: insert_result
  def filled(venue_order_id, submission) do
    order_response = %Responses.Create{
      id: venue_order_id,
      status: :filled,
      original_size: submission.qty,
      leaves_qty: Decimal.new(0),
      cumulative_qty: submission.qty,
      venue_timestamp: Timex.now(),
      received_at: Tai.Time.monotonic_time()
    }

    match_attrs = %{
      symbol: submission.product_symbol,
      price: submission.price,
      size: submission.qty,
      time_in_force: :ioc
    }

    {:create_order, match_attrs}
    |> Mocks.Server.insert(order_response)
  end
end
