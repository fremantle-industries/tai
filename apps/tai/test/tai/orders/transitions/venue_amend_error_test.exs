defmodule Tai.Orders.Transitions.VenueAmendErrorTest do
  use ExUnit.Case, async: false
  alias Tai.Orders.Transitions

  test ".attrs/1 returns a list of updatable order attributes" do
    transition = %Transitions.VenueAmendError{}

    attrs = Transitions.VenueAmendError.attrs(transition)
    assert length(attrs) == 0
  end
end
