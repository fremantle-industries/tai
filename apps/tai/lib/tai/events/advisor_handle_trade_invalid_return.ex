defmodule Tai.Events.AdvisorHandleTradeInvalidReturn do
  @type fleet_id :: Tai.Fleets.FleetConfig.id()
  @type advisor_id :: Tai.Fleets.AdvisorConfig.advisor_id()
  @type t :: %__MODULE__{
          advisor_id: advisor_id,
          fleet_id: fleet_id,
          event: term,
          return_value: term
        }

  @enforce_keys ~w[advisor_id fleet_id event return_value]a
  defstruct ~w[advisor_id fleet_id event return_value]a

  defimpl TaiEvents.LogEvent do
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
end
