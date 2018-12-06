defmodule Tai.Venue do
  @type config :: Tai.Config.t()
  @type adapter :: Tai.Venues.Adapter.t()
  @type product :: Tai.Venues.Product.t()
  @type asset_balance :: Tai.Venues.AssetBalance.t()

  @doc """
  Parse a map of exchange configurations into a list of adapter structs
  """
  @spec parse_adapters() :: [adapter]
  @spec parse_adapters(config :: config) :: [adapter]
  def parse_adapters(%Tai.Config{} = config \\ Tai.Config.parse()) do
    config.venues
    |> Enum.map(fn {id, params} ->
      %Tai.Venues.Adapter{
        id: id,
        adapter: Keyword.fetch!(params, :adapter),
        products: Keyword.get(params, :products, "*"),
        accounts: Keyword.get(params, :accounts, %{}),
        timeout: Keyword.get(params, :timeout, config.adapter_timeout)
      }
    end)
  end

  @spec products(adapter :: adapter) :: {:ok, [product]}
  def products(%Tai.Venues.Adapter{adapter: adapter, id: exchange_id}) do
    adapter.products(exchange_id)
  end

  @spec asset_balances(adapter :: adapter, account_id :: atom) :: {:ok, [asset_balance]}
  def asset_balances(
        %Tai.Venues.Adapter{adapter: adapter, id: exchange_id, accounts: accounts},
        account_id
      ) do
    {:ok, credentials} = Map.fetch(accounts, account_id)
    adapter.asset_balances(exchange_id, account_id, credentials)
  end

  @spec maker_taker_fees(adapter :: adapter, account_id :: atom) ::
          {:ok, {maker :: Decimal.t(), taker :: Decimal.t()}}
  def maker_taker_fees(
        %Tai.Venues.Adapter{adapter: adapter, id: exchange_id, accounts: accounts},
        account_id
      ) do
    {:ok, credentials} = Map.fetch(accounts, account_id)
    adapter.maker_taker_fees(exchange_id, account_id, credentials)
  end
end
