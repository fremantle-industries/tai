defmodule Tai.Orders.Transitions.RescueCancelErrorTest do
  use ExUnit.Case, async: false
  alias Tai.Orders.Transitions

  test ".attrs/1 returns a list of updatable order attributes" do
    transition = %Transitions.RescueCancelError{}

    attrs = Transitions.RescueCancelError.attrs(transition)
    assert Enum.empty?(attrs)
  end
end
