defmodule Tai.NewOrders.Transitions.PendCancelTest do
  use ExUnit.Case, async: false
  alias Tai.NewOrders.Transitions

  test ".attrs/1 returns a list of updatable order attributes" do
    transition = %Transitions.PendCancel{}

    attrs = Transitions.PendCancel.attrs(transition)
    assert length(attrs) == 0
  end
end
