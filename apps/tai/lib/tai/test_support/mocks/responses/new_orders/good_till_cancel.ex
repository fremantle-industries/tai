defmodule Tai.TestSupport.Mocks.Responses.NewOrders.GoodTillCancel do
  alias Tai.TestSupport.Mocks
  alias Tai.NewOrders.{Order, Submissions}
  alias Tai.NewOrders

  @type order :: Order.t()
  @type buy_limit :: Submissions.BuyLimitGtc.t()
  @type sell_limit :: Submissions.SellLimitGtc.t()
  @type submission :: buy_limit | sell_limit
  @type venue_order_id :: String.t()
  @type insert_result :: :ok

  @spec create_accepted(venue_order_id, submission) :: :ok
  def create_accepted(venue_order_id, submission) do
    order_response = %NewOrders.Responses.CreateAccepted{
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

    order_response = %NewOrders.Responses.Create{
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

    order_response = %NewOrders.Responses.Create{
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
    order_response = %NewOrders.Responses.Create{
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

  @spec amend_accepted(
    order,
    %{optional(:price) => Decimal.t(), optional(:qty) => Decimal.t()},
    %{optional(:received_at) => DateTime.t(), optional(:venue_timestamp) => DateTime.t()}
  ) :: :ok
  def amend_accepted(venue_order_id, match_attrs, response_attrs \\ %{}) do
    merged_response_attrs = Map.merge(%{
      id: venue_order_id,
      received_at: DateTime.utc_now(),
      venue_timestamp: DateTime.utc_now()
    }, response_attrs)
    order_response = struct!(NewOrders.Responses.AmendAccepted, merged_response_attrs)
    merged_match_attrs = Map.merge(%{venue_order_id: venue_order_id}, match_attrs)

    {:amend_order, merged_match_attrs}
    |> Mocks.Server.insert(order_response)
  end

  @deprecated "Use amend_price_and_qty with venue_order_id instead."
  def amend_price_and_qty(order, price, qty) do
    amend_price_and_qty(order.venue_order_id, price, qty)
  end

  @spec amend_bulk_accepted([{order, %{}}], [map]) :: :ok
  def amend_bulk_accepted(amend_set, response_attrs \\ []) do
    order_responses =
      amend_set
      |> Enum.with_index()
      |> Enum.map(fn {{order, _attrs}, idx} ->
        order_response_attrs = Enum.at(response_attrs, idx) || %{}
        merged_response_attrs = Map.merge(%{
          id: order.venue_order_id,
          venue_timestamp: DateTime.utc_now(),
          received_at: DateTime.utc_now()
        }, order_response_attrs)

        struct!(NewOrders.Responses.AmendAccepted, merged_response_attrs)
      end)

    response = %NewOrders.Responses.AmendBulk{orders: order_responses}

    match_attrs =
      Enum.map(amend_set, fn {order, attrs} ->
        %{
          venue_order_id: order.venue_order_id,
          price: Map.get(attrs, :price),
          qty: Map.get(attrs, :qty)
        }
      end)

    {:amend_bulk_orders, match_attrs}
    |> Mocks.Server.insert(response)
  end

  @spec amend_bulk_price_and_qty([{order, %{}}]) :: :ok
  def amend_bulk_price_and_qty(amend_set) do
    order_responses =
      Enum.map(amend_set, fn {order, _attrs} ->
        %NewOrders.Responses.AmendAccepted{
          id: order.venue_order_id,
          venue_timestamp: DateTime.utc_now(),
          received_at: Tai.Time.monotonic_time()
        }
      end)

    response = %NewOrders.Responses.AmendBulk{orders: order_responses}

    match_attrs =
      Enum.map(amend_set, fn {order, attrs} ->
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
      Enum.map(orders_and_attrs, fn {order, _attrs} ->
        %NewOrders.Responses.AmendAccepted{
          id: order.venue_order_id,
          venue_timestamp: DateTime.utc_now(),
          received_at: Tai.Time.monotonic_time()
        }
      end)

    response = %NewOrders.Responses.AmendBulk{orders: order_responses}

    match_attrs =
      Enum.map(orders_and_attrs, fn {order, attrs} ->
        %{venue_order_id: order.venue_order_id, price: Map.get(attrs, :price)}
      end)

    {:amend_bulk_orders, match_attrs}
    |> Mocks.Server.insert(response)
  end

  @spec cancel_accepted(venue_order_id) :: :ok
  def cancel_accepted(venue_order_id, attrs \\ %{}) do
    merged_attrs = Map.merge(%{
      id: venue_order_id,
      venue_timestamp: DateTime.utc_now(),
      received_at: Tai.Time.monotonic_time()
    }, attrs)

    order_response = struct!(NewOrders.Responses.CancelAccepted, merged_attrs)

    {:cancel_order, venue_order_id}
    |> Mocks.Server.insert(order_response)
  end
end
