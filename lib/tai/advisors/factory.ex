defmodule Tai.Advisors.Factory do
  @type group :: Tai.AdvisorGroup.t()
  @type spec :: Tai.Advisor.spec()

  @callback advisor_specs(group) :: [spec]
end
