defmodule Tai.Events.OrderUpdateInvalidStatus do
  alias Tai.Events.OrderUpdateInvalidStatus

  @type order_status :: Tai.Trading.Order.status()
  @type t :: %OrderUpdateInvalidStatus{
          client_id: Tai.Trading.Order.client_id(),
          action: atom,
          was: order_status,
          required: order_status | [order_status]
        }

  @enforce_keys [
    :client_id,
    :action,
    :was,
    :required
  ]
  defstruct [
    :client_id,
    :action,
    :was,
    :required
  ]
end
