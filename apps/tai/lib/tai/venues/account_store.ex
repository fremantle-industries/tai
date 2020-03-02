defmodule Tai.Venues.AccountStore do
  use Stored.Store

  @topic_namespace :account_store

  def after_put(account) do
    Tai.SystemBus.broadcast(
      {@topic_namespace, {account.venue_id, account.credential_id, account.asset, account.type}},
      {@topic_namespace, :after_put, account}
    )
  end
end
