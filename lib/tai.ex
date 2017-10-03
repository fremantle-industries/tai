defmodule Tai do
  use Application

  def start(_type, _args) do
    Tai.Supervisor.start_link()
  end
end
