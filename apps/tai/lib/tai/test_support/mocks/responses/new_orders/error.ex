defmodule Tai.TestSupport.Mocks.Responses.NewOrders.Error do
  alias Tai.TestSupport.Mocks
  alias Tai.NewOrders.{Order, Submissions, SubmissionFactory}

  @type buy_limit :: Submissions.BuyLimitGtc.t()
  @type sell_limit :: Submissions.SellLimitGtc.t()
  @type submission :: buy_limit | sell_limit
  @type venue_order_id :: Order.venue_order_id()
  @type order :: Order.t()
  @type amend_attrs :: map
  @type reason :: term

  @spec create_raise(submission, reason) :: :ok
  def create_raise(submission, reason) do
    changeset = SubmissionFactory.order_changeset(submission)

    match_attrs = %{
      symbol: Ecto.Changeset.get_field(changeset, :product_symbol),
      price: Ecto.Changeset.get_field(changeset, :price),
      size: Ecto.Changeset.get_field(changeset, :qty),
      time_in_force: Ecto.Changeset.get_field(changeset, :time_in_force)
    }

    {:create_order, match_attrs}
    |> Mocks.Server.insert({:raise, reason})
  end

  @spec amend_raise(venue_order_id, amend_attrs, reason) :: :ok
  def amend_raise(venue_order_id, attrs, reason) do
    match_attrs = Map.merge(%{venue_order_id: venue_order_id}, attrs)

    {:amend_order, match_attrs}
    |> Mocks.Server.insert({:raise, reason})
  end

  @spec amend_bulk_raise([map], reason) :: :ok
  def amend_bulk_raise(match_attrs, reason) do
    {:amend_bulk_orders, match_attrs}
    |> Mocks.Server.insert({:raise, reason})
  end

  @spec cancel_raise(venue_order_id, reason) :: :ok
  def cancel_raise(venue_order_id, reason) do
    {:cancel_order, venue_order_id}
    |> Mocks.Server.insert({:raise, reason})
  end
end
