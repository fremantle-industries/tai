defmodule Tai.Venues.StreamsSupervisor do
  use DynamicSupervisor

  @type venue :: Tai.Venue.t()
  @type product :: Tai.Venues.Product.t()
  @type account :: Tai.Venues.Account.t()

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @spec start(venue, [product], [account]) :: DynamicSupervisor.on_start_child()
  def start(venue, products, accounts) do
    spec =
      {venue.adapter.stream_supervisor, [venue: venue, products: products, accounts: accounts]}

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def stop(pid) when is_pid(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  def which_children do
    DynamicSupervisor.which_children(__MODULE__)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
