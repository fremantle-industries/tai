defmodule Tai.Orders.Responses.CreateAccepted do
  @moduledoc """
  Returned from venue adapters when accepted for creation. Updates to the order 
  will be received from the stream.
  """

  alias __MODULE__

  @type t :: %CreateAccepted{
          id: Tai.Orders.Order.venue_order_id(),
          received_at: integer,
          venue_timestamp: DateTime.t() | nil
        }

  @enforce_keys ~w[id received_at]a
  defstruct ~w[id received_at venue_timestamp]a
end
