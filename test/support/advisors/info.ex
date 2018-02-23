defmodule Support.Advisors.Info do
  use Tai.Advisor

  require Logger

  def handle_quotes(state, feed_id, symbol, changes) do
    Logger.debug "[#{state.advisor_id |> Tai.Advisor.to_name}] handle_quotes - feed_id: #{feed_id}, symbol: #{symbol}, changes: #{inspect changes}"

    {:ok, %{}}
  end
end
