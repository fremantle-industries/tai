defmodule Support.Advisors.Info do
  use GenServer
  alias Tai.Advisor

  def start_link(advisor_id) do
    {:ok, started_at, _offset} = DateTime.from_iso8601("2010-01-13T14:21:06+00:00")

    GenServer.start_link(
      __MODULE__,
      {advisor_id, started_at},
      name: advisor_id |> Advisor.to_name
    )
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:info, _from, {advisor_id, started_at}) do
    {:reply, started_at, {advisor_id, started_at}}
  end
end
