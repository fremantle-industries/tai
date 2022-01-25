defmodule Tai.Venues.AccountStore do
  use Stored.Store

  @topic_namespace :account_store

  def after_put(account) do
    msg = {@topic_namespace, :after_put, account}
    :ok = Tai.SystemBus.broadcast(@topic_namespace, msg)
  end
end
