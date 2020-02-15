defmodule Tai.Config do
  @moduledoc """
  Convert the application environment into a struct
  """

  @type t :: %Tai.Config{
          adapter_timeout: pos_integer,
          advisor_groups: map,
          broadcast_change_set: boolean,
          event_registry_partitions: pos_integer,
          send_orders: boolean,
          system_bus_registry_partitions: pos_integer,
          venue_boot_handler: module,
          venues: map
        }

  @enforce_keys ~w(
    adapter_timeout
    advisor_groups
    event_registry_partitions
    send_orders
    system_bus_registry_partitions
    venue_boot_handler
    venues
  )a
  defstruct ~w(
    adapter_timeout
    advisor_groups
    broadcast_change_set
    event_registry_partitions
    send_orders
    system_bus_registry_partitions
    venue_boot_handler
    venues
  )a

  def parse(env \\ Application.get_all_env(:tai)) do
    schedulers_online = System.schedulers_online()

    %Tai.Config{
      adapter_timeout: get(env, :adapter_timeout, 10_000),
      advisor_groups: get(env, :advisor_groups, %{}),
      broadcast_change_set: !!get(env, :broadcast_change_set),
      event_registry_partitions: get(env, :event_registry_partitions, schedulers_online),
      send_orders: !!get(env, :send_orders),
      system_bus_registry_partitions:
        get(env, :system_bus_registry_partitions, schedulers_online),
      venue_boot_handler: get(env, :venue_boot_handler, Tai.Venues.BootHandler),
      venues: get(env, :venues, %{})
    }
  end

  defp get(env, key, default \\ nil), do: Keyword.get(env, key, default)
end
