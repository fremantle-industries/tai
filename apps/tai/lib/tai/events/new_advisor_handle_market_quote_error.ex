defmodule Tai.Events.NewAdvisorHandleMarketQuoteError do
  @type fleet_id :: Tai.Fleets.FleetConfig.id()
  @type advisor_id :: Tai.Fleets.AdvisorConfig.advisor_id()
  @type t :: %__MODULE__{
          advisor_id: advisor_id,
          fleet_id: fleet_id,
          event: term,
          error: term,
          stacktrace: term
        }

  @enforce_keys ~w[
    advisor_id
    fleet_id
    event
    error
    stacktrace
  ]a
  defstruct ~w[
    advisor_id
    fleet_id
    event
    error
    stacktrace
  ]a

  defimpl TaiEvents.LogEvent do
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
end
