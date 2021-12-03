defmodule Tai.Orders.Transitions do
  alias __MODULE__

  @type transition ::
    Transitions.AcceptAmend.t()
    | Transitions.AcceptCancel.t()
    | Transitions.AcceptCreate.t()
    | Transitions.Amend.t()
    | Transitions.Cancel.t()
    | Transitions.Expire.t()
    | Transitions.Fill.t()
    | Transitions.Open.t()
    | Transitions.PartialFill.t()
    | Transitions.PendAmend.t()
    | Transitions.PendCancel.t()
    | Transitions.Reject.t()
    | Transitions.RescueAmendError.t()
    | Transitions.RescueCancelError.t()
    | Transitions.RescueCreateError.t()
    | Transitions.Skip.t()
    | Transitions.VenueAmendError.t()
    | Transitions.VenueCancelError.t()
    | Transitions.VenueCreateError.t()
end
