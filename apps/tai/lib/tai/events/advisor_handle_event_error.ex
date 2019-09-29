defmodule Tai.Events.AdvisorHandleEventError do
  alias __MODULE__

  @type group_id :: Tai.AdvisorGroup.id()
  @type advisor_id :: Tai.Advisor.advisor_id()
  @type t :: %AdvisorHandleEventError{
          advisor_id: advisor_id,
          group_id: group_id,
          event: term,
          error: term,
          stacktrace: term
        }

  @enforce_keys ~w(
    advisor_id
    group_id
    event
    error
    stacktrace
  )a
  defstruct ~w(
    advisor_id
    group_id
    event
    error
    stacktrace
  )a
end

defimpl Tai.LogEvent, for: Tai.Events.AdvisorHandleEventError do
  def to_data(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    event
    |> Map.take(keys)
    |> Map.put(:event, event.event |> inspect)
    |> Map.put(:error, event.error |> inspect)
    |> Map.put(:stacktrace, event.stacktrace |> inspect)
  end
end
