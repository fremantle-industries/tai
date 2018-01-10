defmodule Tai.Exchanges.OrderBookFeedsSupervisor do
  use Supervisor

  alias Tai.Exchanges.Config

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    Config.order_book_feed_ids
    |> to_children
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp to_children(feed_ids) do
    feed_ids
    |> Enum.map(&config_to_child_spec/1)
  end

  defp config_to_child_spec(feed_id) do
    %{
      id: "#{Tai.Exchanges.OrderBookFeedSupervisor}_#{feed_id}",
      start: {Tai.Exchanges.OrderBookFeedSupervisor, :start_link, [feed_id]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end
end
