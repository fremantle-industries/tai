defmodule Tai.Exchanges.Supervisor do
  use Supervisor

  alias Tai.Exchanges.Config

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Enum.concat(exchange_supervisors(), [Tai.Exchanges.OrderBookFeedsSupervisor])
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp exchange_supervisors do
    Config.exchange_supervisors()
    |> Enum.map(fn {exchange_id, supervisor} ->
      Supervisor.child_spec(
        {supervisor, exchange_id},
        id: "#{supervisor}_#{exchange_id}"
      )
    end)
  end
end
