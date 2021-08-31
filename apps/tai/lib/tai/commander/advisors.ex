defmodule Tai.Commander.Advisors do
  def get(options) do
    Tai.NewAdvisors.search_instances(options)
  end
end
