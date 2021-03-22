defmodule Tai.Trading.OrderStore.Actions.PendAmend do
  @moduledoc """
  The order is going to be sent to the venue to be amended
  """

  alias Tai.Trading.OrderStore.Actions.PendAmend

  @type client_id :: Tai.Trading.Order.client_id()
  @type t :: %PendAmend{client_id: client_id}

  @enforce_keys ~w[client_id]a
  defstruct ~w[client_id]a
end

defimpl Tai.Trading.OrderStore.Action, for: Tai.Trading.OrderStore.Actions.PendAmend do
  def required(_), do: [:open, :partially_filled, :amend_error]

  def attrs(_action) do
    %{
      status: :pending_amend,
      error_reason: nil
    }
  end
end
