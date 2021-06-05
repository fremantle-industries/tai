defmodule Tai.NewOrders.Transitions.RescueCreateErrorTest do
  use ExUnit.Case, async: false
  alias Tai.NewOrders.Transitions

  test ".attrs/1 returns a list of updatable order attributes" do
    transition = %Transitions.RescueCreateError{}

    attrs = Transitions.RescueCreateError.attrs(transition)
    assert length(attrs) == 1
    assert attrs[:leaves_qty] == Decimal.new(0)
  end
end
