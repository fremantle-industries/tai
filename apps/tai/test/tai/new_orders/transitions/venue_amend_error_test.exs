defmodule Tai.NewOrders.Transitions.VenueAmendErrorTest do
  use ExUnit.Case, async: false
  alias Tai.NewOrders.Transitions

  test ".attrs/1 returns a list of updatable order attributes" do
    transition = %Transitions.VenueAmendError{}

    attrs = Transitions.VenueAmendError.attrs(transition)
    assert length(attrs) == 0
  end
end
