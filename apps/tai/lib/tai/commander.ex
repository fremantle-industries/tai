defmodule Tai.Commander do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def accounts(options \\ []) do
    options |> to_dest() |> GenServer.call(:accounts)
  end

  def products(options \\ []) do
    options |> to_dest() |> GenServer.call(:products)
  end

  def fees(options \\ []) do
    options |> to_dest() |> GenServer.call(:fees)
  end

  def markets(options \\ []) do
    options |> to_dest() |> GenServer.call(:markets)
  end

  def orders(options \\ []) do
    options |> to_dest() |> GenServer.call(:orders)
  end

  def positions(options \\ []) do
    options |> to_dest() |> GenServer.call(:positions)
  end

  def venues(options \\ []) do
    options |> to_dest() |> GenServer.call({:venues, options})
  end

  def start_venue(venue_id, options \\ []) do
    options |> to_dest |> GenServer.call({:start_venue, venue_id, options})
  end

  def stop_venue(venue_id, options \\ []) do
    options |> to_dest |> GenServer.call({:stop_venue, venue_id, options})
  end

  def advisors(options \\ []) do
    options |> to_dest |> GenServer.call({:advisors, options})
  end

  def start_advisors(options \\ []) do
    options |> to_dest |> GenServer.call({:start_advisors, options})
  end

  def stop_advisors(options \\ []) do
    options |> to_dest |> GenServer.call({:stop_advisors, options})
  end

  def settings(options \\ []) do
    options |> to_dest |> GenServer.call(:settings)
  end

  def enable_send_orders(options \\ []) do
    options |> to_dest |> GenServer.call(:enable_send_orders)
  end

  def disable_send_orders(options \\ []) do
    options |> to_dest |> GenServer.call(:disable_send_orders)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:accounts, _from, state) do
    {:reply, Tai.Commander.Accounts.get(), state}
  end

  def handle_call(:products, _from, state) do
    {:reply, Tai.Commander.Products.get(), state}
  end

  def handle_call(:fees, _from, state) do
    {:reply, Tai.Commander.Fees.get(), state}
  end

  def handle_call(:markets, _from, state) do
    {:reply, Tai.Commander.Markets.get(), state}
  end

  def handle_call(:orders, _from, state) do
    {:reply, Tai.Commander.Orders.get(), state}
  end

  def handle_call(:positions, _from, state) do
    {:reply, Tai.Commander.Positions.get(), state}
  end

  def handle_call({:venues, options}, _from, state) do
    {:reply, Tai.Commander.Venues.get(options), state}
  end

  def handle_call({:start_venue, venue_id, options}, _from, state) do
    {:reply, Tai.Commander.StartVenue.execute(venue_id, options), state}
  end

  def handle_call({:stop_venue, venue_id, store_id}, _from, state) do
    {:reply, Tai.Commander.StopVenue.execute(venue_id, store_id), state}
  end

  def handle_call({:advisors, options}, _from, state) do
    {:reply, Tai.Commander.Advisors.get(options), state}
  end

  def handle_call({:start_advisors, options}, _from, state) do
    {:reply, Tai.Commander.StartAdvisors.execute(options), state}
  end

  def handle_call({:stop_advisors, options}, _from, state) do
    {:reply, Tai.Commander.StopAdvisors.execute(options), state}
  end

  def handle_call(:settings, _from, state) do
    {:reply, Tai.Commander.Settings.get(), state}
  end

  def handle_call(:enable_send_orders, _from, state) do
    {:reply, Tai.Commander.EnableSendOrders.execute(), state}
  end

  def handle_call(:disable_send_orders, _from, state) do
    {:reply, Tai.Commander.DisableSendOrders.execute(), state}
  end

  defp to_dest(options) do
    options
    |> Keyword.get(:node)
    |> case do
      nil -> __MODULE__
      node -> {__MODULE__, node}
    end
  end
end
