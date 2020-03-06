defmodule Tai.Application do
  use Application

  def start(_type, _args) do
    Confex.resolve_env!(:tai)
    config = Tai.Config.parse()

    children = [
      {Tai.SystemBus, config.system_bus_registry_partitions},
      Tai.EventsLogger,
      {Tai.Settings, config},
      Tai.Trading.PositionStore,
      Tai.Trading.OrderStore,
      Tai.Markets.QuoteStore,
      Tai.Venues.ProductStore,
      Tai.Venues.FeeStore,
      Tai.Venues.AccountStore,
      Tai.Venues.VenueStore,
      Tai.Venues.StreamsSupervisor,
      Tai.Venues.Supervisor,
      Tai.Advisors.SpecStore,
      Tai.Advisors.Supervisor,
      Tai.Boot
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Tai.Supervisor)
  end

  def start_phase(:venues, _start_type, _phase_args) do
    Tai.Venues.Config.parse()
    |> Enum.map(&Tai.Venues.VenueStore.put/1)
    |> Enum.map(fn {:ok, {_, v}} -> v end)
    |> Enumerati.filter(start_on_boot: true)
    |> Enum.map(&Tai.Boot.register_venue/1)
    |> Enum.map(fn {:ok, v} -> v end)
    |> Enum.map(&Tai.Venues.Supervisor.start(&1))

    Tai.Boot.close_registration()

    :ok
  end
end
