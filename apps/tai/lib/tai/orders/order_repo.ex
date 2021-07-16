defmodule Tai.Orders.OrderRepo do
  use Ecto.Repo,
    otp_app: :tai,
    adapter: Application.get_env(:tai, :order_repo_adapter, Ecto.Adapters.Postgres)
end
