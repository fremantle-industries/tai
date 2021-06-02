defmodule Tai.TestSupport.Factories.OrderTransitionFactory do
  alias Tai.NewOrders.{OrderRepo, OrderTransition}

  def create_order_transition(order_client_id, attrs, type) do
    with {:ok, generated_attrs} <- generate_order_transition_attrs(type),
         merged_attrs <- Map.merge(generated_attrs, attrs) do
      %OrderTransition{}
      |> OrderTransition.changeset(%{order_client_id: order_client_id, transition: merged_attrs})
      |> OrderRepo.insert()
    end
  end

  defp generate_order_transition_attrs(:accept_create = type) do
    attrs = %{
      venue_order_id: Ecto.UUID.generate(),
      last_venue_timestamp: DateTime.utc_now(),
      last_received_at: DateTime.utc_now(),
      __type__: type
    }
    {:ok, attrs}
  end

  defp generate_order_transition_attrs(:venue_create_error = type) do
    attrs = %{
      reason: :some_error,
      __type__: type
    }
    {:ok, attrs}
  end

  defp generate_order_transition_attrs(:cancel = type) do
    attrs = %{
      last_venue_timestamp: DateTime.utc_now(),
      last_received_at: DateTime.utc_now(),
      __type__: type
    }
    {:ok, attrs}
  end

  defp generate_order_transition_attrs(:venue_amend_error = type) do
    attrs = %{
      reason: :some_error,
      __type__: type
    }
    {:ok, attrs}
  end

  defp generate_order_transition_attrs(:partial_fill = type) do
    attrs = %{
      last_venue_timestamp: DateTime.utc_now(),
      last_received_at: DateTime.utc_now(),
      __type__: type
    }
    {:ok, attrs}
  end

  defp generate_order_transition_attrs(_) do
    {:error, :not_implemented}
  end
end
