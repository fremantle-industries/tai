defmodule Tai.TestSupport.Mocks.Responses.Orders.GoodTillCancel do
  alias Tai.TestSupport.Mocks
  alias Tai.Trading.{Order, OrderResponses, OrderSubmissions}

  @type order :: Order.t()
  @type buy_limit :: OrderSubmissions.BuyLimitGtc.t()
  @type sell_limit :: OrderSubmissions.SellLimitGtc.t()
  @type submission :: buy_limit | sell_limit
  @type venue_order_id :: String.t()
  @type insert_result :: :ok

  @spec create_accepted(venue_order_id, submission) :: :ok
  def create_accepted(venue_order_id, submission) do
    order_response = %OrderResponses.CreateAccepted{
      id: venue_order_id,
      venue_timestamp: Timex.now(),
      received_at: Tai.Time.monotonic_time()
    }

    match_attrs = %{
      symbol: submission.product_symbol,
      price: submission.price,
      size: submission.qty,
      time_in_force: :gtc
    }

    {:create_order, match_attrs}
    |> Mocks.Server.insert(order_response)
  end

  @spec open(venue_order_id, submission, map) :: :ok
  def open(venue_order_id, submission, attrs \\ %{}) do
    qty = submission.qty
    cumulative_qty = attrs |> Map.get(:cumulative_qty, Decimal.new(0))
    leaves_qty = Decimal.sub(qty, cumulative_qty)

    order_response = %OrderResponses.Create{
      id: venue_order_id,
      status: :open,
      original_size: qty,
      leaves_qty: leaves_qty,
      cumulative_qty: cumulative_qty,
      venue_timestamp: Timex.now(),
      received_at: Tai.Time.monotonic_time()
    }

    match_attrs = %{
      symbol: submission.product_symbol,
      price: submission.price,
      size: submission.qty,
      time_in_force: :gtc
    }

    {:create_order, match_attrs}
    |> Mocks.Server.insert(order_response)
  end

  @spec rejected(venue_order_id, submission) :: :ok
  def rejected(venue_order_id, submission) do
    qty = submission.qty

    order_response = %OrderResponses.Create{
      id: venue_order_id,
      status: :rejected,
      original_size: qty,
      leaves_qty: Decimal.new(0),
      cumulative_qty: Decimal.new(0),
      venue_timestamp: Timex.now(),
      received_at: Tai.Time.monotonic_time()
    }

    match_attrs = %{
      symbol: submission.product_symbol,
      price: submission.price,
      size: submission.qty,
      time_in_force: :gtc
    }

    {:create_order, match_attrs}
    |> Mocks.Server.insert(order_response)
  end

  @spec filled(submission) :: insert_result
  def filled(submission), do: filled(Ecto.UUID.generate(), submission)

  @spec filled(venue_order_id, submission) :: insert_result
  def filled(venue_order_id, submission) do
    order_response = %OrderResponses.Create{
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
      time_in_force: :gtc
    }

    {:create_order, match_attrs}
    |> Mocks.Server.insert(order_response)
  end

  @spec amend_price(order, Decimal.t()) :: :ok
  def amend_price(order, price) do
    order_response = %OrderResponses.Amend{
      id: order.venue_order_id,
      status: :open,
      price: price,
      leaves_qty: order.leaves_qty,
      cumulative_qty: Decimal.new(0),
      venue_timestamp: Timex.now(),
      received_at: Tai.Time.monotonic_time()
    }

    match_attrs = %{venue_order_id: order.venue_order_id, price: price}

    {:amend_order, match_attrs}
    |> Mocks.Server.insert(order_response)
  end

  @spec amend_price_and_qty(order, Decimal.t(), Decimal.t()) :: :ok
  def amend_price_and_qty(order, price, qty) do
    order_response = %OrderResponses.Amend{
      id: order.venue_order_id,
      status: :open,
      price: price,
      leaves_qty: qty,
      cumulative_qty: Decimal.new(0),
      venue_timestamp: Timex.now(),
      received_at: Tai.Time.monotonic_time()
    }

    match_attrs = %{venue_order_id: order.venue_order_id, price: price, qty: qty}

    {:amend_order, match_attrs}
    |> Mocks.Server.insert(order_response)
  end

  @spec amend_bulk_price_and_qty([{order, %{}}]) :: :ok
  def amend_bulk_price_and_qty(orders_and_attrs) do
    order_responses =
      Enum.map(orders_and_attrs, fn {order, attrs} ->
        %OrderResponses.Amend{
          id: order.venue_order_id,
          status: :open,
          price: Map.get(attrs, :price),
          leaves_qty: Map.get(attrs, :qty),
          cumulative_qty: Decimal.new(0),
          venue_timestamp: Timex.now(),
          received_at: Tai.Time.monotonic_time()
        }
      end)

    response = %OrderResponses.AmendBulk{orders: order_responses}

    match_attrs =
      Enum.map(orders_and_attrs, fn {order, attrs} ->
        %{
          venue_order_id: order.venue_order_id,
          price: Map.get(attrs, :price),
          qty: Map.get(attrs, :qty)
        }
      end)

    {:amend_bulk_orders, match_attrs}
    |> Mocks.Server.insert(response)
  end

  @spec amend_bulk_price([{order, %{}}]) :: :ok
  def amend_bulk_price(orders_and_attrs) do
    order_responses =
      Enum.map(orders_and_attrs, fn {order, attrs} ->
        %OrderResponses.Amend{
          id: order.venue_order_id,
          status: :open,
          price: Map.get(attrs, :price),
          leaves_qty: order.leaves_qty,
          cumulative_qty: Decimal.new(0),
          venue_timestamp: Timex.now(),
          received_at: Tai.Time.monotonic_time()
        }
      end)

    response = %OrderResponses.AmendBulk{orders: order_responses}

    match_attrs =
      Enum.map(orders_and_attrs, fn {order, attrs} ->
        %{venue_order_id: order.venue_order_id, price: Map.get(attrs, :price)}
      end)

    {:amend_bulk_orders, match_attrs}
    |> Mocks.Server.insert(response)
  end

  @spec cancel_accepted(venue_order_id) :: :ok
  def cancel_accepted(venue_order_id) do
    order_response = %OrderResponses.CancelAccepted{
      id: venue_order_id,
      venue_timestamp: Timex.now(),
      received_at: Tai.Time.monotonic_time()
    }

    {:cancel_order, venue_order_id}
    |> Mocks.Server.insert(order_response)
  end

  @spec canceled(venue_order_id) :: :ok
  def canceled(venue_order_id) do
    order_response = %Tai.Trading.OrderResponses.Cancel{
      id: venue_order_id,
      status: :canceled,
      leaves_qty: Decimal.new(0),
      received_at: Tai.Time.monotonic_time(),
      venue_timestamp: Timex.now()
    }

    {:cancel_order, venue_order_id}
    |> Mocks.Server.insert(order_response)
  end
end
