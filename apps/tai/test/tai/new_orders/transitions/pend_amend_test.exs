defmodule Tai.NewOrders.Transitions.PendAmendTest do
  use ExUnit.Case, async: false
  alias Tai.NewOrders.Transitions

  test ".attrs/1 returns a list of updatable order attributes" do
    transition = %Transitions.PendAmend{}

    attrs = Transitions.PendAmend.attrs(transition)
    assert length(attrs) == 0
  end
end
