defmodule Tai.Trading.OrderStore.Actions.Skip do
  @moduledoc """
  Bypass sending the order to the venue
  """

  @type t :: %__MODULE__{client_id: atom}

  @enforce_keys ~w(client_id)a
  defstruct ~w(client_id)a
end

defimpl Tai.Trading.OrderStore.Action, for: Tai.Trading.OrderStore.Actions.Skip do
  def required(_), do: :enqueued
  def attrs(_), do: %{status: :skip, leaves_qty: Decimal.new(0)}
end
