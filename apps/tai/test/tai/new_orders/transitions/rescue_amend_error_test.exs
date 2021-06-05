defmodule Tai.NewOrders.Transitions.RescueAmendErrorTest do
  use ExUnit.Case, async: false
  alias Tai.NewOrders.Transitions

  test ".attrs/1 returns a list of updatable order attributes" do
    transition = %Transitions.RescueAmendError{}

    attrs = Transitions.RescueAmendError.attrs(transition)
    assert length(attrs) == 0
  end
end
