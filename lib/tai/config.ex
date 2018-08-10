defmodule Tai.Config do
  @moduledoc """
  Global config
  """

  def all do
    %{}
    |> Map.put(:send_orders, Application.get_env(:tai, :send_orders, false))
  end
end
