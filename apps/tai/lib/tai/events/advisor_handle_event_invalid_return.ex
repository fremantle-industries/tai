defmodule Tai.Events.AdvisorHandleEventInvalidReturn do
  alias __MODULE__

  @type group_id :: Tai.AdvisorGroup.id()
  @type advisor_id :: Tai.Advisor.advisor_id()
  @type t :: %AdvisorHandleEventInvalidReturn{
          advisor_id: advisor_id,
          group_id: group_id,
          event: term,
          return_value: term
        }

  @enforce_keys ~w(advisor_id group_id event return_value)a
  defstruct ~w(advisor_id group_id event return_value)a
end

defimpl Tai.LogEvent, for: Tai.Events.AdvisorHandleEventInvalidReturn do
  def to_data(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    event
    |> Map.take(keys)
    |> Map.put(:event, event.event |> inspect)
    |> Map.put(:return_value, event.return_value |> inspect)
  end
end
