defmodule Tai.AdvisorResponders.Changes do
  alias Tai.AdvisorResponders.Responder
  @behaviour Responder

  @impl Responder
  def respond({response, state}, {_, _, _, changes}) do
    new_response = Map.put(response, :changes, changes)
    {:ok, {new_response, state}}
  end
end
