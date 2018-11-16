defmodule Tai.Events.CancelOrderInvalidStatus do
  @type order_client_id :: Tai.Trading.Order.client_id()
  @type order_status :: Tai.Trading.Order.status()
  @type t :: %Tai.Events.CancelOrderInvalidStatus{
          client_id: order_client_id,
          was: order_status,
          required: order_status
        }

  @enforce_keys [:client_id, :was, :required]
  defstruct [:client_id, :was, :required]
end
