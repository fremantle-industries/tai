defmodule Tai.Events.OrderErrorAmendHasInvalidStatus do
  @type order_status :: Tai.Trading.Order.status()
  @type t :: %Tai.Events.OrderErrorAmendHasInvalidStatus{
          client_id: atom,
          was: order_status,
          required: :open
        }

  @enforce_keys [
    :client_id,
    :was,
    :required
  ]
  defstruct [
    :client_id,
    :was,
    :required
  ]
end
