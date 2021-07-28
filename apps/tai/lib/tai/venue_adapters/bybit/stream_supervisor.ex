defmodule Tai.VenueAdapters.Bybit.StreamSupervisor do
  use Supervisor

  alias Tai.VenueAdapters.Bybit.Stream.{
    Connection
  }

  @spec start_link(Tai.Venues.Stream.t()) :: Supervisor.on_start()
  def start_link(stream) do
    name = process_name(stream.venue.id)
    Supervisor.start_link(__MODULE__, stream, name: name)
  end

  @spec process_name(Tai.Venue.id()) :: atom
  def process_name(venue), do: :"#{__MODULE__}_#{venue}"

  @impl true
  def init(stream) do
    credential = stream.venue.credentials |> Map.to_list() |> List.first()

    children = [
      {Connection, [endpoint: endpoint(), stream: stream, credential: credential]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  # TODO: Make this configurable
  defp endpoint, do: "wss://stream.bybit.com/realtime"
end
