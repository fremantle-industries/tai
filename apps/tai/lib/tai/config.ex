defmodule Tai.Config do
  @moduledoc """
  Convert the application environment into a struct
  """

  @type func_name :: atom
  @type boot_args :: term
  @type t :: %Tai.Config{
          adapter_timeout: pos_integer,
          advisor_groups: map,
          after_boot: {module, func_name} | {module, func_name, boot_args} | nil,
          after_boot_error: {module, func_name} | {module, func_name, boot_args} | nil,
          broadcast_change_set: boolean,
          send_orders: boolean,
          system_bus_registry_partitions: pos_integer,
          venues: map
        }

  @enforce_keys ~w(
    adapter_timeout
    advisor_groups
    send_orders
    system_bus_registry_partitions
    venues
  )a
  defstruct ~w(
    adapter_timeout
    advisor_groups
    after_boot
    after_boot_error
    broadcast_change_set
    send_orders
    system_bus_registry_partitions
    venues
  )a

  def parse(env \\ Application.get_all_env(:tai)) do
    schedulers_online = System.schedulers_online()

    %Tai.Config{
      adapter_timeout: get(env, :adapter_timeout, 10_000),
      advisor_groups: get(env, :advisor_groups, %{}),
      after_boot: get(env, :after_boot),
      after_boot_error: get(env, :after_boot_error),
      broadcast_change_set: !!get(env, :broadcast_change_set),
      send_orders: !!get(env, :send_orders),
      system_bus_registry_partitions:
        get(env, :system_bus_registry_partitions, schedulers_online),
      venues: get(env, :venues, %{})
    }
  end

  defp get(env, key, default \\ nil), do: Keyword.get(env, key, default)
end
