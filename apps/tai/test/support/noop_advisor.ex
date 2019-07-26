defmodule Support.NoopAdvisor do
  use Tai.Advisor

  def handle_inside_quote(_, _, _, _, state) do
    {:ok, state.store}
  end
end
