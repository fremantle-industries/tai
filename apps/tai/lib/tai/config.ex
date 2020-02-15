defmodule Tai.Config do
  @moduledoc """
  Convert the application environment into a struct
  """

  @type t :: %Tai.Config{
          adapter_timeout: integer,
          advisor_groups: map,
          broadcast_change_set: boolean,
          venue_boot_handler: module,
          event_registry_partitions: pos_integer,
          system_bus_registry_partitions: pos_integer,
          send_orders: boolean,
          venues: map
        }

  @enforce_keys ~w(
    adapter_timeout
    advisor_groups
    venue_boot_handler
    event_registry_partitions
    system_bus_registry_partitions
    send_orders
    venues
  )a
  defstruct ~w(
    adapter_timeout
    advisor_groups
    broadcast_change_set
    event_registry_partitions
    system_bus_registry_partitions
    venue_boot_handler
    send_orders
    venues
  )a

  def parse(env \\ Application.get_all_env(:tai)) do
    adapter_timeout = Keyword.get(env, :adapter_timeout, 10_000)
    advisor_groups = Keyword.get(env, :advisor_groups, %{})
    broadcast_change_set = !!Keyword.get(env, :broadcast_change_set)
    venue_boot_handler = Keyword.get(env, :venue_boot_handler, Tai.Venues.BootHandler)
    send_orders = !!Keyword.get(env, :send_orders)
    venues = Keyword.get(env, :venues, %{})

    event_registry_partitions =
      Keyword.get(env, :event_registry_partitions, System.schedulers_online())

    system_bus_registry_partitions =
      Keyword.get(env, :system_bus_registry_partitions, System.schedulers_online())

    %Tai.Config{
      adapter_timeout: adapter_timeout,
      advisor_groups: advisor_groups,
      broadcast_change_set: broadcast_change_set,
      event_registry_partitions: event_registry_partitions,
      system_bus_registry_partitions: system_bus_registry_partitions,
      venue_boot_handler: venue_boot_handler,
      send_orders: send_orders,
      venues: venues
    }
  end
end
