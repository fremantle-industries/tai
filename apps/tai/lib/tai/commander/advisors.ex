defmodule Tai.Commander.Advisors do
  def get(options) do
    Tai.Advisors.search_instances(options)
  end
end
