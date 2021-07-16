defmodule Tai.IEx.Commands.FailedOrderTransitions do
  @moduledoc """
  Display the list of failed order transitions and their details
  """

  import Tai.IEx.Commands.Table, only: [render!: 2]

  @type client_id :: Tai.Orders.Order.client_id()

  @header [
    "Client ID",
    "Created At",
    "Type"
  ]

  @spec failed_order_transitions(client_id) :: no_return
  def failed_order_transitions(client_id) do
    client_id
    |> Tai.Commander.failed_order_transitions()
    |> Enum.map(fn f ->
      [
        f.order_client_id |> Tai.Utils.String.truncate(6),
        f.inserted_at,
        f.type
      ]
    end)
    |> render!(@header)
  end
end
