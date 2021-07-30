defmodule Tai.Orders.Transitions.PendAmendTest do
  use ExUnit.Case, async: false
  alias Tai.Orders.Transitions

  test ".attrs/1 returns a list of updatable order attributes" do
    transition = %Transitions.PendAmend{}

    attrs = Transitions.PendAmend.attrs(transition)
    assert Enum.empty?(attrs)
  end
end
