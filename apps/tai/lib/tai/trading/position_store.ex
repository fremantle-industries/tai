defmodule Tai.Trading.PositionStore do
  use Stored.Store

  @topic_namespace :position_store

  def after_put(position) do
    Tai.SystemBus.broadcast(
      @topic_namespace,
      {@topic_namespace, :after_put, position}
    )
  end
end
