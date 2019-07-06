defmodule Tai.Advisors.Factory do
  @type group :: Tai.AdvisorGroup.t()
  @type spec :: Tai.Advisors.Spec.t()

  @callback advisor_specs(group) :: [spec]
end
