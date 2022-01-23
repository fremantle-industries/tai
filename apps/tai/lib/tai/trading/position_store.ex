defmodule Tai.Trading.PositionStore do
  use Stored.Store

  @topic_namespace :position_store

  def after_put(position) do
    msg = {@topic_namespace, :after_put, position}
    :ok = Tai.SystemBus.broadcast(@topic_namespace, msg)
  end
end
