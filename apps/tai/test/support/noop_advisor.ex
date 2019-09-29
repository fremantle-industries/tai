defmodule Support.NoopAdvisor do
  use Tai.Advisor

  def handle_event(_, state) do
    {:ok, state.store}
  end
end
