defmodule Tai.Venues.StreamsSupervisor do
  use DynamicSupervisor

  @type product :: Tai.Exchanges.Product.t()
  @type null_supervisor :: Tai.Venues.NullStreamSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec start_stream(
          stream_supervisor :: atom | null_supervisor,
          venue_id :: atom,
          accounts :: map,
          products :: [product]
        ) :: DynamicSupervisor.on_start_child()
  def start_stream(Tai.Venues.NullStreamSupervisor, _, _, _), do: :ignore

  def start_stream(stream_supervisor, venue_id, accounts, products) do
    spec = {stream_supervisor, [venue_id: venue_id, accounts: accounts, products: products]}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
