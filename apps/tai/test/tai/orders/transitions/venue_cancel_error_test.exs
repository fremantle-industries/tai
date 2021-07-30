defmodule Tai.Orders.Transitions.VenueCancelErrorTest do
  use ExUnit.Case, async: false
  alias Tai.Orders.Transitions

  test ".attrs/1 returns a list of updatable order attributes" do
    transition = %Transitions.VenueCancelError{}

    attrs = Transitions.VenueCancelError.attrs(transition)
    assert Enum.empty?(attrs)
  end
end
