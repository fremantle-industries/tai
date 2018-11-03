defmodule Tai.Config do
  @moduledoc """
  Module to parse the config from the application environment
  """

  @type t :: %Tai.Config{
          adapter_timeout: integer,
          advisor_groups: map,
          exchange_boot_handler: atom,
          send_orders: boolean,
          venues: map
        }

  @enforce_keys [
    :adapter_timeout,
    :advisor_groups,
    :exchange_boot_handler,
    :event_registry_partitions,
    :send_orders,
    :venues
  ]
  defstruct [
    :adapter_timeout,
    :advisor_groups,
    :event_registry_partitions,
    :exchange_boot_handler,
    :send_orders,
    :venues
  ]

  def parse(env \\ Application.get_all_env(:tai)) do
    adapter_timeout = Keyword.get(env, :adapter_timeout, 10_000)
    advisor_groups = Keyword.get(env, :advisor_groups, %{})
    exchange_boot_handler = Keyword.get(env, :exchange_boot_handler, Tai.Exchanges.BootHandler)
    send_orders = !!Keyword.get(env, :send_orders)
    venues = Keyword.get(env, :venues, %{})

    event_registry_partitions =
      Keyword.get(env, :event_registry_partitions, System.schedulers_online())

    %Tai.Config{
      adapter_timeout: adapter_timeout,
      advisor_groups: advisor_groups,
      event_registry_partitions: event_registry_partitions,
      exchange_boot_handler: exchange_boot_handler,
      send_orders: send_orders,
      venues: venues
    }
  end
end
