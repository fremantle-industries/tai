defmodule Tai.IEx.Commands.OrderTransitions do
  @moduledoc """
  Display the list of order transitions and their details
  """

  import Tai.IEx.Commands.Table, only: [render!: 2]

  @type client_id :: Tai.Orders.Order.client_id()

  @header [
    "Client ID",
    "Created At",
    "Type",
  ]

  @spec order_transitions(client_id) :: no_return
  def order_transitions(client_id) do
    Tai.Commander.order_transitions(client_id)
    |> Enum.map(fn t ->
      %transition_type{} = t.transition
      [
        t.order_client_id |> Tai.Utils.String.truncate(6),
        t.inserted_at,
        transition_type
      ]
    end)
    |> render!(@header)
  end
end
