defmodule Tai.Orders.Transitions.PendCancelTest do
  use ExUnit.Case, async: false
  alias Tai.Orders.Transitions

  test ".attrs/1 returns a list of updatable order attributes" do
    transition = %Transitions.PendCancel{}

    attrs = Transitions.PendCancel.attrs(transition)
    assert Enum.empty?(attrs)
  end
end
