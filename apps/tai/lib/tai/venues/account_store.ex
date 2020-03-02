defmodule Tai.Venues.AccountStore do
  use Stored.Store

  @topic_namespace :account_store

  def after_put(account) do
    Tai.SystemBus.broadcast(
      @topic_namespace,
      {@topic_namespace, :after_put, account}
    )
  end
end
