defmodule Tai.Config do
  @moduledoc """
  Global configuration for a `tai` instance. This module provides a utility
  function to hydrate a struct from the OTP `Application` environment.

  It can be configured with the following options:

  ```
  # [default: 10_000] [optional] Adapter start timeout in milliseconds
  config :tai, adapter_timeout: 60_000

  # [default: nil] [optional] Handler to call after all venues & advisors have successfully started on boot
  config :tai, after_boot: {Mod, :func_name, []}

  # [default: nil] [optional] Handler to call after any venues or advisors have failed to start on boot
  config :tai, after_boot_error: {Mod, :func_name, []}

  # [default: false] [optional] Flag which enables the forwarding of each order book change set to the system bus
  config :tai, broadcast_change_set: true

  # [default: false] [optional] Flag which enables the sending of orders to the venue. When this is `false`, it
  # acts a safety net by enqueueing and skipping the order transmission to the venue. This is useful in
  # development to prevent accidently sending live orders.
  config :tai, send_orders: true

  # [default: System.schedulers_online] [optional] Number of processes that can forward internal pubsub messages.
  # Defaults to the number of CPU's available in the Erlang VM `System.schedulers_online/0`.
  config :tai, system_bus_registry_partitions: 2

  # [default: %{}] [optional] Map of configured venues. See below for more details.
  config :tai, venues: %{}

  # [default: %{}] [optional] Map of configured advisor groups. See below for more details.
  config :tai, advisor_groups: %{}
  ```
  """

  @type handler :: module
  @type func_name :: atom
  @type boot_args :: term
  @type t :: %Tai.Config{
          adapter_timeout: pos_integer,
          advisor_groups: map,
          after_boot: {handler, func_name} | {handler, func_name, boot_args} | nil,
          after_boot_error: {handler, func_name} | {handler, func_name, boot_args} | nil,
          broadcast_change_set: boolean,
          logger: module,
          order_workers: pos_integer,
          order_workers_max_overflow: non_neg_integer,
          send_orders: boolean,
          system_bus_registry_partitions: pos_integer,
          venues: map
        }

  @enforce_keys ~w[
    adapter_timeout
    advisor_groups
    order_workers
    order_workers_max_overflow
    send_orders
    system_bus_registry_partitions
    venues
  ]a
  defstruct ~w[
    adapter_timeout
    advisor_groups
    after_boot
    after_boot_error
    broadcast_change_set
    logger
    order_workers
    order_workers_max_overflow
    send_orders
    system_bus_registry_partitions
    venues
  ]a

  @spec parse() :: t
  @spec parse([{Application.key(), Application.value()}]) :: t
  def parse(env \\ Application.get_all_env(:tai)) do
    %Tai.Config{
      adapter_timeout: get(env, :adapter_timeout, 10_000),
      advisor_groups: get(env, :advisor_groups, %{}),
      after_boot: get(env, :after_boot),
      after_boot_error: get(env, :after_boot_error),
      broadcast_change_set: !!get(env, :broadcast_change_set),
      logger: get(env, :logger),
      order_workers: get(env, :order_workers, 5),
      order_workers_max_overflow: get(env, :order_workers_max_overflow, 2),
      send_orders: !!get(env, :send_orders),
      system_bus_registry_partitions:
        get(env, :system_bus_registry_partitions, System.schedulers_online()),
      venues: get(env, :venues, %{})
    }
  end

  defp get(env, key, default \\ nil), do: Keyword.get(env, key, default)
end
