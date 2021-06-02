defmodule Tai.NewOrders.Services.ApplyOrderTransition do
  require Ecto.Query
  import Ecto.Query

  alias Tai.NewOrders.{
    FailedOrderTransition,
    Order,
    OrderCallbackStore,
    OrderRepo,
    OrderTransition,
    Services
  }

  @moduledoc """
  ApplyOrderTransition is responsible for the modification of an order's state and
  the recording of an audit history from the applied and attempted changes.

  If a transition fails validation or attempts the transition on an order with an
  unsupported status, it will rollback any attempted changes and record an entry in
  the `FailedOrderTransition` schema.
  """

  @type order :: Order.t()
  @type client_id :: Order.client_id()
  @type attrs :: %{
          required(:__type__) => atom,
          optional(atom) => term
        }

  @spec call(client_id, attrs) :: {:ok, order} | {:error, term}
  def call(client_id, %{__type__: _} = transition_attrs) do
    try do
      changeset =
        OrderTransition.changeset(
          %OrderTransition{},
          %{order_client_id: client_id, transition: transition_attrs}
        )
      transition = Ecto.Changeset.get_field(changeset, :transition)

      if changeset.valid? do
        client_id
        |> update_order_and_save_transition(transition, changeset)
        |> execute_order_callback(client_id, transition, transition_attrs)
        |> clear_resting_order_callback()
      else
        reason = PolymorphicEmbed.traverse_errors(changeset, &reduce_errors/1)
        save_failed_transition(client_id, transition_attrs, reason)
        {:error, reason}
      end
    rescue
      e ->
        save_failed_transition(client_id, transition_attrs, e)
        {:error, e}
    end
  end

  def call(client_id, transition_attrs) do
    error = %RuntimeError{
      message: "could not infer polymorphic embed from data #{inspect(transition_attrs)}"
    }

    save_failed_transition(client_id, transition_attrs, error)
    {:error, error}
  end

  defp update_order_and_save_transition(client_id, %transition_mod{} = transition, order_transition_changeset) do
    from_status = transition_mod.from()
    attrs = transition_mod.attrs(transition)
    update_order_query = build_update_order_query(client_id, from_status, attrs)

    # The previous order needs to be selected outside of the transaction to
    # prevent a possible deadlock.
    case OrderRepo.get(Order, client_id) do
      %Order{} = previous_order_before_update ->
        # Check if the existing order has a status that supports this
        # transition in memory and only rely on the transaction rollback
        # as a fallback. There is a performance penalty to rolling back
        # a transaction.
        if Enum.member?(from_status, previous_order_before_update.status) do
          fn ->
            case OrderRepo.update_all(update_order_query, []) do
              {0, []} ->
                status_was = previous_order_before_update.status
                reason = {:invalid_status, status_was}
                OrderRepo.rollback(reason)

              {1, [current_order]} ->
                case OrderRepo.insert(order_transition_changeset) do
                  {:ok, _} -> {previous_order_before_update, current_order}
                  {:error, reason} -> OrderRepo.rollback(reason)
                end

              {:error, reason} ->
                OrderRepo.rollback(reason)
            end
          end
          |> OrderRepo.transaction()
        else
          status_was = previous_order_before_update.status
          reason = {:invalid_status, status_was}
          {:error, reason}
        end

      nil ->
        {:error, :order_not_found}
    end
  end

  defp build_update_order_query(client_id, from_status, attrs) do
    from(o in Order,
      update: [set: ^attrs],
      where: o.client_id == ^client_id and o.status in ^from_status,
      select: %Order{
        client_id: o.client_id,
        close: o.close,
        credential: o.credential,
        cumulative_qty: o.cumulative_qty,
        last_received_at: o.last_received_at,
        last_venue_timestamp: o.last_venue_timestamp,
        leaves_qty: o.leaves_qty,
        post_only: o.post_only,
        price: o.price,
        product_symbol: o.product_symbol,
        product_type: o.product_type,
        qty: o.qty,
        side: o.side,
        status: o.status,
        time_in_force: o.time_in_force,
        type: o.type,
        venue: o.venue,
        venue_order_id: o.venue_order_id,
        venue_product_symbol: o.venue_product_symbol
      }
    )
  end

  defp execute_order_callback({:ok, {previous_order, current_order}}, _, transition, _) do
    Services.ExecuteOrderCallback.call(previous_order, current_order, transition)
    {:ok, current_order}
  end

  defp execute_order_callback({:error, :order_not_found} = error, _, _, _) do
    error
  end

  defp execute_order_callback({:error, reason} = error, client_id, _transition, transition_attrs) do
    save_failed_transition(client_id, transition_attrs, reason)
    error
  end

  @resting_status ~w(canceled filled create_error)a
  defp clear_resting_order_callback({:ok, %Order{client_id: client_id, status: status}} = result) when status in @resting_status do
    {:ok, _} = OrderCallbackStore.delete(client_id)
    result
  end

  defp clear_resting_order_callback({:ok, _} = result), do: result
  defp clear_resting_order_callback({:error, _} = error), do: error

  defp reduce_errors({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end

  defp save_failed_transition(client_id, transition_attrs, error) do
    type =
      transition_attrs
      |> Map.get(:__type__)
      |> case do
        nil -> nil
        t -> Atom.to_string(t)
      end

    {:ok, _} =
      %FailedOrderTransition{}
      |> FailedOrderTransition.changeset(%{
        order_client_id: client_id,
        type: type,
        error: error
      })
      |> OrderRepo.insert()
  end
end
